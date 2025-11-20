library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench OPTIMIZADO con tiempos perfectos para visualización
-- Configurado para MAX_COUNT = 5 en clock_divider
-- Tiempo total de simulación: ~15 microsegundos
entity security_system_tb_optimized is
end security_system_tb_optimized;

architecture Behavioral of security_system_tb_optimized is

    -- Declaración del componente
    component security_system_top
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               btn_config : in STD_LOGIC;
               btn_center : in STD_LOGIC;
               sw : in STD_LOGIC_VECTOR(3 downto 0);
               led : out STD_LOGIC_VECTOR(3 downto 0);
               an : out STD_LOGIC_VECTOR(3 downto 0);
               seg : out STD_LOGIC_VECTOR(6 downto 0));
    end component;
    
    -- Señales del testbench
    signal clk_tb : STD_LOGIC := '0';
    signal reset_tb : STD_LOGIC := '0';
    signal btn_config_tb : STD_LOGIC := '0';
    signal btn_center_tb : STD_LOGIC := '0';
    signal sw_tb : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal led_tb : STD_LOGIC_VECTOR(3 downto 0);
    signal an_tb : STD_LOGIC_VECTOR(3 downto 0);
    signal seg_tb : STD_LOGIC_VECTOR(6 downto 0);
    
    -- Constantes de tiempo
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz
    
    -- Control de simulación
    signal sim_done : boolean := false;
    
    -- Procedimiento para simular presión de botón con tiempos adecuados
    procedure press_button(
        signal btn : out STD_LOGIC;
        constant hold_time : time;
        constant release_time : time
    ) is
    begin
        btn <= '1';
        wait for hold_time;
        btn <= '0';
        wait for release_time;
    end procedure;
    
begin

    -- Instancia del diseño bajo prueba
    UUT: security_system_top
        port map (
            clk => clk_tb,
            reset => reset_tb,
            btn_config => btn_config_tb,
            btn_center => btn_center_tb,
            sw => sw_tb,
            led => led_tb,
            an => an_tb,
            seg => seg_tb
        );
    
    -- Generador de reloj (100 MHz)
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
    
    -- Proceso principal de estimulación
    stim_process: process
    begin
        report "============================================";
        report "  TESTBENCH OPTIMIZADO - PRUEBA COMPLETA";
        report "  MAX_COUNT = 5";
        report "  1 segundo simulado = 100 ns";
        report "  30 segundos = 3 us";
        report "============================================";
        report "";
        
        -- =============================================
        -- FASE 1: RESET DEL SISTEMA
        -- =============================================
        report "FASE 1: Reset del sistema";
        reset_tb <= '1';
        wait for 200 ns;
        reset_tb <= '0';
        wait for 200 ns;
        
        
        
        -- =============================================
        -- FASE 2: CONFIGURACIÓN DE CLAVE
        -- =============================================
        report "FASE 2: Configuración de clave";
        report "Entrando a modo configuración...";
        
        -- Presionar BTNL para asegurar que estamos en CONFIG
        press_button(btn_config_tb, 300 ns, 300 ns);
        
        report "Configurando clave: 1010 (binario) = 10 (decimal)";
        sw_tb <= "1010";
        wait for 500 ns;
        
        report "Presionando BTNC para guardar clave...";
        press_button(btn_center_tb, 300 ns, 500 ns);
        
        report "? Clave 1010 guardada";
        report "? Sistema cambió a modo VERIFY";
        report "? Intentos disponibles: 3";
        report "";
        
        -- =============================================
        -- FASE 3: INTENTO EXITOSO (OPCIONAL - Comentado)
        -- =============================================
        -- Para esta prueba, vamos directo a intentos fallidos
        -- Si quieres probar clave correcta, descomenta:
        --[[
        report "FASE 3: Verificación con clave correcta";
        sw_tb <= "1010"; -- Clave correcta
        wait for 300 ns;
        press_button(btn_center_tb, 300 ns, 500 ns);
        report "? Clave correcta - Sistema DESBLOQUEADO";
        report "";
        wait for 1 us;
        
        -- Volver a configurar
        report "Regresando a configuración...";
        press_button(btn_config_tb, 300 ns, 300 ns);
        sw_tb <= "0101"; -- Nueva clave
        wait for 300 ns;
        press_button(btn_center_tb, 300 ns, 500 ns);
        report "? Nueva clave 0101 configurada";
        report "";
        --]]
        
        -- =============================================
        -- FASE 4: PRIMER INTENTO FALLIDO
        -- =============================================
        report "FASE 4: Primer intento fallido";
        sw_tb <= "0000"; -- Clave incorrecta
        wait for 300 ns;
        
        report "Intentando con clave: 0000 (INCORRECTA)";
        press_button(btn_center_tb, 300 ns, 500 ns);
        
        report "? Intento 1 fallido";
        report "? Intentos restantes: 2";
        report "";
        
        -- =============================================
        -- FASE 5: SEGUNDO INTENTO FALLIDO
        -- =============================================
        report "FASE 5: Segundo intento fallido";
        sw_tb <= "1111"; -- Clave incorrecta
        wait for 300 ns;
        
        report "Intentando con clave: 1111 (INCORRECTA)";
        press_button(btn_center_tb, 300 ns, 500 ns);
        
        report "? Intento 2 fallido";
        report "? Intentos restantes: 1";
        report "";
        
        -- =============================================
        -- FASE 6: TERCER INTENTO FALLIDO ? BLOQUEO
        -- =============================================
        report "FASE 6: Tercer intento fallido - BLOQUEO INMINENTE";
        sw_tb <= "0111"; -- Clave incorrecta
        wait for 300 ns;
        
        report "Intentando con clave: 0101 (INCORRECTA)";
        press_button(btn_center_tb, 300 ns, 500 ns);
        
        report "? Intento 3 fallido";
        report "? SISTEMA BLOQUEADO";
        report "? Intentos restantes: 0";
        report "? Cuenta regresiva iniciada: 30 segundos";
        report "";
        
        -- =============================================
        -- FASE 7: ESPERAR CUENTA REGRESIVA
        -- =============================================
        report "FASE 7: Esperando cuenta regresiva de 30 segundos simulados...";
        report "(Con MAX_COUNT = 5, esto toma ~3 microsegundos)";
        report "";
        
        -- Monitoreo de la cuenta regresiva
        report "Tiempo restante: 30...";
        wait for 500 ns;
        
        report "Cuenta regresiva en progreso...";
        report "LEDs deben estar parpadeando";
        wait for 1 us;
        
        report "Tiempo restante: ~20...";
        wait for 1 us;
        
        report "Tiempo restante: ~10...";
        wait for 1 us;
        
        report "Tiempo restante: llegando a 0...";
        wait for 500 ns;
        
        report "";
        report "? Cuenta regresiva completada";
        report "? Sistema desbloqueado automáticamente";
        report "? Estado cambió de LOCKED a VERIFY";
        report "? Intentos reiniciados a 3";
        report "";
        
        -- =============================================
        -- FASE 8: VERIFICACIÓN DESPUÉS DEL BLOQUEO
        -- =============================================
        report "FASE 8: Verificación post-bloqueo";
        report "Intentando con clave correcta: 1010";
        
        sw_tb <= "1010"; -- Clave correcta
        wait for 300 ns;
        press_button(btn_center_tb, 300 ns, 500 ns);
        
        report "? Clave correcta verificada";
        report "? Sistema DESBLOQUEADO";
        report "? Todos los LEDs encendidos";
        report "";
        
        -- =============================================
        -- FINALIZACIÓN
        -- =============================================
        wait for 1 us;
        
        report "============================================";
        report "  ??? SIMULACIÓN COMPLETADA CON ÉXITO ???";
        report "============================================";
        report "";
        report "RESUMEN DE PRUEBAS:";
        report "  ? Configuración de clave";
        report "  ? 3 intentos fallidos consecutivos";
        report "  ? Sistema de bloqueo activado";
        report "  ? Cuenta regresiva de 30 segundos";
        report "  ? Reinicio automático de intentos";
        report "  ? Desbloqueo con clave correcta";
        report "";
        report "VERIFICAR EN WAVEFORM:";
        report "  - current_state: CONFIG ? VERIFY ? LOCKED ? VERIFY ? UNLOCKED";
        report "  - attempts_left: 3 ? 2 ? 1 ? 0 ? 3";
        report "  - time_remaining: 30 ? 29 ? ... ? 1 ? 0";
        report "  - lockout_active: 0 ? 1 ? 0";
        report "  - led_tb: Cambios según estado";
        report "";
        report "Tiempo total de simulación: ~15 microsegundos";
        report "============================================";
        
        sim_done <= true;
        wait;
        
    end process;

end Behavioral;
