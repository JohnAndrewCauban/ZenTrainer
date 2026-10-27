using System.Diagnostics;
using System.Runtime.InteropServices;

// Battle Realms Zen Edition v1.59.1 Trainer (single-player only).
// Modernized successor to ICECHEAT's 2001 "Battle Realms Trainer +8 (V1.02)".

const string ProcessName = "Battle_Realms_F";

static void LogCrash(string where, Exception e)
{
    var dir = Path.GetDirectoryName(Environment.ProcessPath) ?? AppContext.BaseDirectory;
    File.AppendAllText(Path.Combine(dir, "crashLog.txt"),
        $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {where}\n{e}\n\n");
}

AppDomain.CurrentDomain.UnhandledException += (_, args) =>
{
    var e = (Exception)args.ExceptionObject;
    LogCrash("Unhandled exception", e);
    Console.WriteLine($"\nCRASH: {e.Message}\nDetails saved to crashLog.txt. Press Enter to close.");
    Console.ReadLine();
};

Console.Title = "Battle Realms Zen Trainer";
Console.WriteLine("=====================================================================");
Console.WriteLine(" Battle Realms Zen Trainer (v1.59.1) - SINGLE PLAYER ONLY");
Console.WriteLine("=====================================================================");
Console.WriteLine(" [F1] Fill Resources        (Toggle ON/OFF)");
Console.WriteLine(" [F2] Create Peasant        (Hotkey)");
Console.WriteLine(" [F3] Reveal Map            (Toggle ON/OFF)");
Console.WriteLine(" [F4] Build/Heal Building   (Hotkey)");
Console.WriteLine(" [F5] Instant Train/Upgrade (Toggle ON/OFF)");
Console.WriteLine(" [F6] +10 Yin Points        (Hotkey)");
Console.WriteLine(" [F7] +10 Yang Points       (Hotkey)");
Console.WriteLine(" [F8] Unit Limit 500        (Toggle ON/OFF)");
Console.WriteLine(" [Ctrl+F12] Exit Trainer");
Console.WriteLine("=====================================================================\n");

int? savedLimit = null;

var features = new Dictionary<int, Feature>
{
    [0x70] = new("Fill resources")
    {
        Toggle = true,
        Continuous = true,
        Action = g =>
        {
            var p = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x513228);
            if (p == IntPtr.Zero) return false;
            g.TryWriteInt(p + 0xD4, g.ReadInt(p + 0xDC));
            g.TryWriteInt(p + 0xD8, g.ReadInt(p + 0xE0));
            return true;
        }
    },

    [0x71] = new("Create peasant")
    {
        Action = g =>
        {
            var huts = GetActiveBuildings(g, filterMaxHp: 650);
            foreach (var hut in huts)
            {
                g.TryWriteInt(hut + 0x490, 0x00FFFFFF);
                g.TryWriteInt(hut + 0x4B4, 0x00FFFFFF);
            }
            return huts.Count > 0;
        }
    },

    [0x72] = new("Reveal map")
    {
        Toggle = true,
        Continuous = false, // Only call once on toggle
        Action = g =>
        {
            var p = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x513228);
            if (p == IntPtr.Zero) return false;
            return g.CallRemote(g.BaseAddress + 0xDA029); // DisableFogOfWar
        },
        OnDisable = g =>
        {
            var p = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x513228);
            if (p == IntPtr.Zero) return;
            g.CallRemote(g.BaseAddress + 0xDA01C); // EnableFogOfWar
        }
    },

    [0x73] = new("Build/Heal building")
    {
        Action = g =>
        {
            var p = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x513228);
            int localPlayerId = p != IntPtr.Zero ? g.ReadInt(p + 0x6C) : -1;
            var list = GetActiveBuildings(g, playerOnly: true);
            var sel = GetSelectedBuilding(g);
            if (sel != IntPtr.Zero && IsPlayerBuilding(g, sel, localPlayerId) && !list.Contains(sel))
                list.Add(sel);

            foreach (var b in list)
            {
                var typeDef = (IntPtr)(uint)g.ReadInt(b + 0x258);
                if (typeDef == IntPtr.Zero || (uint)typeDef < 0x01000000) continue;
                int maxHp = g.ReadInt(typeDef + 0x2C);
                if (maxHp <= 0) continue;

                int targetMaxHp = maxHp << 16;
                int isConstructed = g.ReadInt(b + 0xCC);

                if (isConstructed == 0)
                {
                    // Scaffold under construction:
                    // Set HP to 99.9% (0.5 HP short) so exactly one peasant hammer tap completes it naturally.
                    // This lets the game engine fire its native "Build Complete" announcement and register full ownership.
                    g.TryWriteInt(b + 0x88, targetMaxHp);
                    g.TryWriteInt(b + 0x8C, targetMaxHp - 0x8000);
                    g.TryWriteInt(b + 0x90, 0x0000FF00); // 99.6% progress
                }
                else
                {
                    // Finished building: restore 100% HP and extinguish all fire damage
                    g.TryWriteInt(b + 0x88, targetMaxHp);
                    g.TryWriteInt(b + 0x8C, targetMaxHp);
                    g.TryWriteInt(b + 0x80, 0);  // Clear fire damage-over-time accumulator
                    g.TryWriteInt(b + 0x2E8, 0); // Clear active flame effects count
                }
            }
            return list.Count > 0;
        }
    },

    // F5: Instant training/upgrade. Selected building + any of your buildings mid-training.
    [0x74] = new("Instant training/upgrade")
    {
        Toggle = true,
        Continuous = true,
        Action = g =>
        {
            var p = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x513228);
            int localPlayerId = p != IntPtr.Zero ? g.ReadInt(p + 0x6C) : -1;
            var sel = GetSelectedBuilding(g);
            if (sel != IntPtr.Zero && IsPlayerBuilding(g, sel, localPlayerId))
            {
                g.TryWriteInt(sel + 0x490, 0x00FFFFFF);
                g.TryWriteInt(sel + 0x4B4, 0x00FFFFFF);
            }
            // +0x490 / +0x4BC are live progress counters (rise while training/upgrading).
            foreach (var b in GetActiveBuildings(g, playerOnly: true))
                foreach (int off in new[] { 0x490, 0x4B4, 0x4BC })
                {
                    int t = g.ReadInt(b + off);
                    if (t > 0 && t < 0x3FFFFFFF) g.TryWriteInt(b + off, 0x3FFFFFFF);
                }
            // Warlock's Tower keeps its duel/training timer in a sub-object: [tower+0x4C0]+0x14.
            foreach (var b in GetActiveBuildings(g, playerOnly: true))
            {
                var td = (IntPtr)(uint)g.ReadInt(b + 0x258);
                if ((uint)td < 0x01000000) continue;
                var np = (IntPtr)(uint)g.ReadInt(td + 4);
                if ((uint)np < 0x01000000) continue;
                var nameBytes = g.Read(np, 40);
                if (nameBytes.Length == 0 || !System.Text.Encoding.Unicode.GetString(nameBytes).Contains("Warlock")) continue;
                var sub = (IntPtr)(uint)g.ReadInt(b + 0x4C0);
                if ((uint)sub < 0x01000000) continue;
                int t = g.ReadInt(sub + 0x14);
                if (t > 0 && t < 0x3FFFFFFF) g.TryWriteInt(sub + 0x14, 0x3FFFFFFF);
            }
            return true;
        }
    },

    [0x75] = new("10x Yin") { Action = g => AddToPlayer(g, 0x2E4, 10) },
    [0x76] = new("10x Yang") { Action = g => AddToPlayer(g, 0x2E8, 10) },

    [0x77] = new("Unit limit 500")
    {
        Toggle = true,
        Continuous = false, // Only set once on toggle
        Action = g =>
        {
            var addr = LimitAddress(g);
            if (addr == IntPtr.Zero) return false;
            int cur = g.ReadInt(addr);
            if (cur != 500)
            {
                savedLimit = cur;
                g.TryWriteInt(addr, 500);
            }
            else if (savedLimit == null)
            {
                // If already at 500 when trainer attached, read the mission's true configured cap
                savedLimit = ReadConfiguredLimit(g);
            }
            return true;
        },
        OnDisable = g =>
        {
            var addr = LimitAddress(g);
            if (addr == IntPtr.Zero) return;
            // Restore whatever this specific campaign mission or skirmish setup was configured to
            int? orig = savedLimit ?? ReadConfiguredLimit(g);
            if (orig is int target && target > 0 && target != 500)
            {
                g.TryWriteInt(addr, target);
                Console.WriteLine($"  (unit limit restored to {target})");
            }
            else
            {
                Console.WriteLine("  (unit limit toggle OFF)");
            }
            savedLimit = null;
        },
    },
};

// Reads the scenario / skirmish configured unit cap stored in the player table (pPlayer + 0x4AC + playerId * 0x28).
static int? ReadConfiguredLimit(GameProcess g)
{
    var p = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x513228);
    if (p == IntPtr.Zero) return null;
    int playerId = g.ReadInt(p + 0x6C);
    if (playerId < 0 || playerId > 7) return null;
    int configured = g.ReadInt(p + 0x4AC + playerId * 0x28);
    return (configured > 0 && configured != 500) ? configured : null;
}

static IntPtr LimitAddress(GameProcess g)
{
    var p = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x513228);
    if (p == IntPtr.Zero) return IntPtr.Zero;
    return g.BaseAddress + 0x539728 + 4 * g.ReadInt(p + 0x6C);
}

static bool AddToPlayer(GameProcess g, int offset, int amount)
{
    var p = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x513228);
    if (p == IntPtr.Zero) return false;
    g.TryWriteInt(p + offset, g.ReadInt(p + offset) + amount);
    return true;
}

// Currently selected building pointer lives at exe base + 0x554AC0 (entity tag 0x68 at +0x6A0).
static IntPtr GetSelectedBuilding(GameProcess g)
{
    var sel = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x554AC0);
    if (sel == IntPtr.Zero) return IntPtr.Zero;
    return g.ReadInt(sel + 0x6A0) == 0x68 ? sel : IntPtr.Zero;
}

static bool IsPlayerBuilding(GameProcess g, IntPtr bldg, int localPlayerId)
{
    if (localPlayerId >= 0)
    {
        // [bldg + 0x84] holds the true player slot ID (0-7) across all skirmish and campaign matches.
        int ownerId = g.ReadInt(bldg + 0x84);
        if (ownerId == localPlayerId) return true;
    }
    return false;
}

static List<IntPtr> GetActiveBuildings(GameProcess g, int filterMaxHp = 0, bool playerOnly = true)
{
    var list = new List<IntPtr>();
    var arrayBase = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x553568);
    if (arrayBase == IntPtr.Zero) return list;

    var p = (IntPtr)(uint)g.ReadInt(g.BaseAddress + 0x513228);
    int localPlayerId = p != IntPtr.Zero ? g.ReadInt(p + 0x6C) : -1;

    for (int i = 0; i < 500; i++)
    {
        var bldg = arrayBase + i * 0x6A4;
        if (g.ReadInt(bldg + 0x6A0) != 0x68) continue;
        if (playerOnly && !IsPlayerBuilding(g, bldg, localPlayerId)) continue;
        var typeDef = (IntPtr)(uint)g.ReadInt(bldg + 0x258);
        if (typeDef == IntPtr.Zero || (uint)typeDef < 0x01000000) continue;
        if (filterMaxHp > 0 && g.ReadInt(typeDef + 0x2C) != filterMaxHp) continue;
        list.Add(bldg);
    }
    return list;
}

GameProcess? game = null;
var down = new HashSet<int>();

while (true)
{
    if (IsDown(0x11) && IsDown(0x7B)) // Ctrl+F12: restore everything, then quit
    {
        if (game != null && !game.HasExited)
            foreach (var f in features.Values.Where(f => f.Toggle && f.Enabled)) f.OnDisable?.Invoke(game);
        break;
    }

    if (game == null || game.HasExited)
    {
        if (game != null)
        {
            Console.WriteLine("\n[Game process closed. Waiting for Battle_Realms_F...]");
            game.Dispose();
            game = null;
            // Reset active toggles so they don't unexpectedly trigger before the player is ready
            foreach (var f in features.Values.Where(f => f.Toggle)) f.Enabled = false;
        }

        try { game = GameProcess.Attach(ProcessName); }
        catch (Exception e)
        {
            LogCrash("Attach failed", e);
            game = null;
            Thread.Sleep(1000);
            continue;
        }

        if (game != null) Console.WriteLine($"Attached to {ProcessName} (PID {game.Pid}). Base: 0x{game.BaseAddress:X}");
        else { Thread.Sleep(1000); continue; }
    }

    foreach (var (vk, feature) in features)
    {
        bool pressed = IsDown(vk);
        if (pressed && down.Add(vk))
        {
            try
            {
                if (feature.Toggle)
                {
                    feature.Enabled = !feature.Enabled;
                    if (feature.Enabled) feature.Run(game);
                    else feature.OnDisable?.Invoke(game);
                    Console.WriteLine($"{feature.Name}: {(feature.Enabled ? "ON" : "OFF")}");
                }
                else Console.WriteLine($"{feature.Name}: {(feature.Run(game) ? "OK" : "failed")}");
            }
            catch (Exception e) { LogCrash(feature.Name, e); Console.WriteLine($"{feature.Name}: failed - {e.Message}"); }
        }
        else if (!pressed) down.Remove(vk);
    }

    // Only run continuous toggles if active and when the player controller is actually loaded in-game
    bool inGame = (uint)game.ReadInt(game.BaseAddress + 0x513228) >= 0x01000000;
    if (inGame)
    {
        foreach (var feature in features.Values.Where(f => f.Toggle && f.Enabled && f.Continuous))
        {
            try { feature.Run(game); }
            catch (Exception e)
            {
                feature.Enabled = false;
                LogCrash(feature.Name, e);
                Console.WriteLine($"{feature.Name}: failed, switched OFF - {e.Message}");
            }
        }
    }

    Thread.Sleep(50);
}

static bool IsDown(int vk) => (NativeMethods.GetAsyncKeyState(vk) & 0x8000) != 0;

record Feature(string Name)
{
    public Func<GameProcess, bool>? Action { get; init; }
    public bool Toggle { get; init; }
    public bool Continuous { get; init; } = true;
    public Action<GameProcess>? OnDisable { get; init; }
    public bool Enabled { get; set; }
    public bool Run(GameProcess g) => Action != null && Action(g);
}

sealed class GameProcess : IDisposable
{
    readonly IntPtr handle;
    public int Pid { get; }
    public IntPtr BaseAddress { get; }
    readonly Process process;

    public bool HasExited
    {
        get
        {
            try { return process.HasExited; }
            catch { return true; }
        }
    }

    GameProcess(Process p, IntPtr h, IntPtr baseAddress)
    {
        process = p; handle = h; Pid = p.Id;
        BaseAddress = baseAddress;
    }

    public static GameProcess? Attach(string name)
    {
        Process? p = null;
        try
        {
            p = Process.GetProcessesByName(name).FirstOrDefault();
            if (p == null || p.HasExited) return null;

            var baseAddr = p.MainModule?.BaseAddress ?? IntPtr.Zero;
            if (baseAddr == IntPtr.Zero) return null;

            var h = NativeMethods.OpenProcess(0x1F0FFF, false, p.Id);
            if (h == IntPtr.Zero) return null;

            return new GameProcess(p, h, baseAddr);
        }
        catch
        {
            // Process may be initializing or in the process of shutting down
            return null;
        }
    }

    public byte[] Read(IntPtr addr, int len)
    {
        var buf = new byte[len];
        if (!NativeMethods.ReadProcessMemory(handle, addr, buf, (IntPtr)len, out _))
            return Array.Empty<byte>();
        return buf;
    }

    public int ReadInt(IntPtr addr)
    {
        var buf = Read(addr, 4);
        return buf.Length == 4 ? BitConverter.ToInt32(buf, 0) : 0;
    }

    public bool TryWrite(IntPtr addr, byte[] data) =>
        NativeMethods.WriteProcessMemory(handle, addr, data, (IntPtr)data.Length, out _);

    public bool TryWriteInt(IntPtr addr, int v) => TryWrite(addr, BitConverter.GetBytes(v));

    public bool CallRemote(IntPtr fnAddr)
    {
        IntPtr hThread = NativeMethods.CreateRemoteThread(handle, IntPtr.Zero, IntPtr.Zero, fnAddr, IntPtr.Zero, 0, out _);
        if (hThread == IntPtr.Zero) return false;
        NativeMethods.WaitForSingleObject(hThread, 3000);
        NativeMethods.CloseHandle(hThread);
        return true;
    }

    public void Dispose()
    {
        if (handle != IntPtr.Zero) NativeMethods.CloseHandle(handle);
        process.Dispose();
    }
}

static class NativeMethods
{
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(int access, bool inherit, int pid);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, IntPtr size, out IntPtr read);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteProcessMemory(IntPtr h, IntPtr addr, byte[] buf, IntPtr size, out IntPtr written);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr a, IntPtr s, IntPtr start, IntPtr p, uint f, out IntPtr id);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint WaitForSingleObject(IntPtr h, uint ms);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr h);
}
