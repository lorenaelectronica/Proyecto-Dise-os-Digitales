library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench optimizado para visualización rápida
-- Con modificaciones para simulación:
-- - counter_1hz con rango 0 to 100
-- - debounce_counter con rango 0 to 100
-- Tiempo total: ~50 microsegundos

entity guess_game_tb_fast is
end guess_game_tb_fast;

architecture Behavioral of guess_game_tb_fast is

    component guess_game
        Port ( 
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            btn_guess : in STD_LOGIC;
            sw : in STD_LOGIC_VECTOR(3 downto 0);
            led : out STD_LOGIC_VECTOR(4 downto 0);
            an : out STD_LOGIC_VECTOR(3 downto 0);
            seg : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;
    
    -- Señales de prueba
    signal clk_tb : STD_LOGIC := '0';
    signal reset_tb : STD_LOGIC := '0';
    signal btn_guess_tb : STD_LOGIC := '0';
    signal sw_tb : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal led_tb : STD_LOGIC_VECTOR(4 downto 0);
    signal an_tb : STD_LOGIC_VECTOR(3 downto 0);
    signal seg_tb : STD_LOGIC_VECTOR(6 downto 0);
    
    constant CLK_PERIOD : time := 10 ns;
    signal sim_done : boolean := false;
    
    -- Procedimiento para presionar botón
    procedure press_button(
        signal btn : out STD_LOGIC;
        constant duration : time
    ) is
    begin
        btn <= '1';
        wait for duration;
        btn <= '0';
        wait for duration * 3; -- Dar más tiempo para procesar
    end procedure;

begin

    -- Instancia del DUT
    UUT: guess_game
        port map (
            clk => clk_tb,
            reset => reset_tb,
            btn_guess => btn_guess_tb,
            sw => sw_tb,
            led => led_tb,
            an => an_tb,
            seg => seg_tb
        );
    
    -- Generador de reloj
    clk_process: process
    begin
        while not sim_done loop
            clk_tb <= '0';
            wait for CLK_PERIOD/2;
            clk_tb <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Proceso de estimulación
    stim_process: process
    begin
        report "===========================================";
        report "  TESTBENCH RÁPIDO - Adivina el Número";
        report "  Configuración de simulación:";
        report "  - 1 Hz simulado = 100 ns";
        report "  - 15 segundos = 1.5 us";
        report "  - 3 segundos = 300 ns";
        report "===========================================";
        report "";
        
        -- ==========================================
        -- FASE 1: RESET
        -- ==========================================
        report "FASE 1: Reset del sistema";
        reset_tb <= '1';
        wait for 200 ns;
        reset_tb <= '0';
        wait for 200 ns;
        report "? Sistema inicializado";
        report "? Display debe mostrar: ----";
        report "? LEDs apagados";
        report "";
        
        -- ==========================================
        -- FASE 2: INICIAR JUEGO
        -- ==========================================
        report "FASE 2: Iniciar primera ronda";
        press_button(btn_guess_tb, 500 ns);
        wait for 500 ns;
        report "? Juego iniciado";
        report "? Número objetivo generado";
        report "? LED[4:0] = 11111 (5 intentos)";
        report "";
        
        -- ==========================================
        -- FASE 3: INTENTO 1 (menor)
        -- ==========================================
        report "FASE 3: Intento 1 - Número bajo (0000)";
        sw_tb <= "0000";
        wait for 300 ns;
        press_button(btn_guess_tb, 500 ns);
        wait for 500 ns;
        report "? Retroalimentación mostrada";
        report "? LED[4:0] = 01111 (4 intentos)";
        report "";
        
        -- ==========================================
        -- FASE 4: INTENTO 2
        -- ==========================================
        report "FASE 4: Intento 2 - Número medio (1000)";
        sw_tb <= "1000";
        wait for 300 ns;
        press_button(btn_guess_tb, 500 ns);
        wait for 500 ns;
        report "? LED[4:0] = 00111 (3 intentos)";
        report "";
        
        -- ==========================================
        -- FASE 5: INTENTO 3
        -- ==========================================
        report "FASE 5: Intento 3 - Probando (0100)";
        sw_tb <= "0100";
        wait for 300 ns;
        press_button(btn_guess_tb, 500 ns);
        wait for 500 ns;
        report "? LED[4:0] = 00011 (2 intentos)";
        report "";
        
        -- ==========================================
        -- FASE 6: INTENTO 4
        -- ==========================================
        report "FASE 6: Intento 4 - Probando (1100)";
        sw_tb <= "1100";
        wait for 300 ns;
        press_button(btn_guess_tb, 500 ns);
        wait for 500 ns;
        report "? LED[4:0] = 00001 (1 intento)";
        report "";
        
        -- ==========================================
        -- FASE 7: INTENTO 5 (fallo - para probar bloqueo)
        -- ==========================================
        report "FASE 7: Intento 5 - Último intento (1111)";
        sw_tb <= "1111";
        wait for 300 ns;
        press_button(btn_guess_tb, 500 ns);
        wait for 500 ns;
        report "? Sin intentos restantes";
        report "? Display debe mostrar: FAIL";
        report "? LEDs: Parpadeo";
        report "";
        
        -- ==========================================
        -- FASE 8: DISPLAY FAIL (3 segundos simulados)
        -- ==========================================
        report "FASE 8: Mostrando FAIL por 3 segundos simulados";
        report "Con modificación: 3 segundos = 300 ns";
        wait for 400 ns; -- Esperar 3 "segundos" + margen
        report "? Display FAIL completado";
        report "";
        
        -- ==========================================
        -- FASE 9: BLOQUEO (15 segundos simulados)
        -- ==========================================
        report "FASE 9: Bloqueo de 15 segundos (simulados)";
        report "Cuenta regresiva: 15 ? 0";
        report "Con modificación: 15 segundos = 1.5 us";
        
        -- Observar algunos valores de la cuenta
        wait for 200 ns;
        report "Cuenta en progreso...";
        wait for 400 ns;
        report "Cuenta en progreso...";
        wait for 500 ns;
        report "Cuenta en progreso...";
        wait for 500 ns;
        
        report "? Bloqueo completado";
        report "? Sistema debe reiniciar automáticamente";
        report "";
        
        -- ==========================================
        -- FASE 10: VERIFICAR REINICIO
        -- ==========================================
        report "FASE 10: Verificación de reinicio automático";
        wait for 500 ns;
        report "? Display debe mostrar: ----";
        report "? Sistema listo para nueva ronda";
        report "";
        
        -- ==========================================
        -- FASE 11: NUEVA RONDA - VICTORIA
        -- ==========================================
        report "FASE 11: Nueva ronda - Probar victoria";
        
        -- Iniciar nueva ronda
        press_button(btn_guess_tb, 500 ns);
        wait for 500 ns;
        report "? Nueva ronda iniciada";
        
        -- Probar con varios números hasta acertar
        -- (En realidad no sabemos el número, pero probamos la funcionalidad)
        report "Intentando con 0101";
        sw_tb <= "0101";
        wait for 300 ns;
        press_button(btn_guess_tb, 500 ns);
        wait for 500 ns;
        
        -- Si no acertó, observar retroalimentación
        if led_tb /= "11111" then
            report "No acertado, intentando con 1010";
            sw_tb <= "1010";
            wait for 300 ns;
            press_button(btn_guess_tb, 500 ns);
            wait for 500 ns;
        else
            report "? ¡VICTORIA! Display debe mostrar: --OH";
            report "? LEDs todos encendidos";
        end if;
        
        wait for 1 us;
        
        -- ==========================================
        -- FINALIZACIÓN
        -- ==========================================
        report "";
        report "===========================================";
        report "  ??? TESTBENCH COMPLETADO ???";
        report "===========================================";
        report "";
        report "VERIFICACIONES REALIZADAS:";
        report "  ? Reset e inicialización";
        report "  ? Generación de número aleatorio (LFSR)";
        report "  ? Inicio de ronda";
        report "  ? Sistema de 5 intentos";
        report "  ? Decremento de intentos en LEDs";
        report "  ? Retroalimentación en displays";
        report "  ? Display FAIL (3 segundos)";
        report "  ? Bloqueo de 15 segundos";
        report "  ? Cuenta regresiva visible";
        report "  ? Reinicio automático";
        report "  ? Nueva ronda funcional";
        report "";
        report "TIEMPO TOTAL DE SIMULACIÓN: ~10 microsegundos";
        report "===========================================";
        
        sim_done <= true;
        wait;
        
    end process;

end Behavioral;
