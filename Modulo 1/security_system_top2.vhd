library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Módulo principal del sistema de seguridad - VERSIÓN CORREGIDA
entity security_system_top is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           -- Botones
           btn_config : in STD_LOGIC;  -- BTNL - Modo configuración
           btn_center : in STD_LOGIC;  -- BTNC - Confirmar/Verificar
           -- Switches para clave
           sw : in STD_LOGIC_VECTOR(3 downto 0);
           -- LEDs
           led : out STD_LOGIC_VECTOR(3 downto 0);
           -- Display 7 segmentos
           an : out STD_LOGIC_VECTOR(3 downto 0);
           seg : out STD_LOGIC_VECTOR(6 downto 0));
end security_system_top;

architecture Behavioral of security_system_top is

    -- Declaración de componentes
    component clock_divider
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               clk_1hz : out STD_LOGIC);
    end component;
    
    component debouncer
        Generic ( DEBOUNCE_TIME : integer := 1000000);
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               button_in : in STD_LOGIC;
               button_out : out STD_LOGIC);
    end component;
    
    component edge_detector
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               signal_in : in STD_LOGIC;
               edge_detected : out STD_LOGIC);
    end component;
    
    component key_storage
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               config_mode : in STD_LOGIC;
               save_key : in STD_LOGIC;
               new_key : in STD_LOGIC_VECTOR(3 downto 0);
               stored_key : out STD_LOGIC_VECTOR(3 downto 0));
    end component;
    
    component key_verification
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               verify_key : in STD_LOGIC;
               input_key : in STD_LOGIC_VECTOR(3 downto 0);
               stored_key : in STD_LOGIC_VECTOR(3 downto 0);
               key_correct : out STD_LOGIC;
               key_incorrect : out STD_LOGIC);
    end component;
    
    component attempt_counter
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               failed_attempt : in STD_LOGIC;
               reset_attempts : in STD_LOGIC;
               attempts_left : out STD_LOGIC_VECTOR(1 downto 0);
               max_attempts_reached : out STD_LOGIC);
    end component;
    
    component lockout_timer
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               clk_1hz : in STD_LOGIC;
               start_lockout : in STD_LOGIC;
               lockout_active : out STD_LOGIC;
               time_remaining : out STD_LOGIC_VECTOR(5 downto 0));
    end component;
    
    component bcd_converter
        Port ( binary_in : in STD_LOGIC_VECTOR(5 downto 0);
               tens : out STD_LOGIC_VECTOR(3 downto 0);
               ones : out STD_LOGIC_VECTOR(3 downto 0));
    end component;
    
    component seven_segment_driver
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               digit0 : in STD_LOGIC_VECTOR(3 downto 0);
               digit1 : in STD_LOGIC_VECTOR(3 downto 0);
               digit2 : in STD_LOGIC_VECTOR(3 downto 0);
               digit3 : in STD_LOGIC_VECTOR(3 downto 0);
               an : out STD_LOGIC_VECTOR(3 downto 0);
               seg : out STD_LOGIC_VECTOR(6 downto 0));
    end component;

    -- Señales internas
    signal clk_1hz : STD_LOGIC;
    signal btn_config_db, btn_center_db : STD_LOGIC;
    signal btn_config_edge, btn_center_edge : STD_LOGIC;
    
    signal stored_key : STD_LOGIC_VECTOR(3 downto 0);
    signal key_correct, key_incorrect : STD_LOGIC;
    signal attempts_left : STD_LOGIC_VECTOR(1 downto 0);
    signal max_attempts : STD_LOGIC;
    signal lockout_active : STD_LOGIC;
    signal time_remaining : STD_LOGIC_VECTOR(5 downto 0);
    
    signal digit0, digit1, digit2, digit3 : STD_LOGIC_VECTOR(3 downto 0);
    signal bcd_tens, bcd_ones : STD_LOGIC_VECTOR(3 downto 0);
    
    -- Máquina de estados
    type state_type is (CONFIG, VERIFY, LOCKED, UNLOCKED);
    signal current_state, next_state : state_type := CONFIG;
    
    signal reset_attempts : STD_LOGIC := '0';
    signal start_lockout : STD_LOGIC := '0';
    signal config_mode : STD_LOGIC := '0';
    signal verify_key_signal : STD_LOGIC := '0';

begin

    -- Instancia del divisor de reloj
    clk_div: clock_divider
        port map (
            clk => clk,
            reset => reset,
            clk_1hz => clk_1hz
        );
    
    -- Debouncers para botones (CONFIGURADOS PARA SIMULACIÓN)
    db_config: debouncer
        generic map ( DEBOUNCE_TIME => 3 )
        port map (
            clk => clk,
            reset => reset,
            button_in => btn_config,
            button_out => btn_config_db
        );
    
    db_center: debouncer
        generic map ( DEBOUNCE_TIME => 3 )
        port map (
            clk => clk,
            reset => reset,
            button_in => btn_center,
            button_out => btn_center_db
        );
    
    -- Detectores de flanco
    edge_config: edge_detector
        port map (
            clk => clk,
            reset => reset,
            signal_in => btn_config_db,
            edge_detected => btn_config_edge
        );
    
    edge_center: edge_detector
        port map (
            clk => clk,
            reset => reset,
            signal_in => btn_center_db,
            edge_detected => btn_center_edge
        );
    
    -- Almacenamiento de clave
    key_store: key_storage
        port map (
            clk => clk,
            reset => reset,
            config_mode => config_mode,
            save_key => btn_center_edge,
            new_key => sw,
            stored_key => stored_key
        );
    
    -- Verificación de clave
    key_verify: key_verification
        port map (
            clk => clk,
            reset => reset,
            verify_key => verify_key_signal,
            input_key => sw,
            stored_key => stored_key,
            key_correct => key_correct,
            key_incorrect => key_incorrect
        );
    
    -- Contador de intentos
    attempt_cnt: attempt_counter
        port map (
            clk => clk,
            reset => reset,
            failed_attempt => key_incorrect,
            reset_attempts => reset_attempts,
            attempts_left => attempts_left,
            max_attempts_reached => max_attempts
        );
    
    -- Temporizador de bloqueo
    lockout_tmr: lockout_timer
        port map (
            clk => clk,
            reset => reset,
            clk_1hz => clk_1hz,
            start_lockout => start_lockout,
            lockout_active => lockout_active,
            time_remaining => time_remaining
        );
    
    -- Convertidor BCD
    bcd_conv: bcd_converter
        port map (
            binary_in => time_remaining,
            tens => bcd_tens,
            ones => bcd_ones
        );
    
    -- Driver de displays
    display_driver: seven_segment_driver
        port map (
            clk => clk,
            reset => reset,
            digit0 => digit0,
            digit1 => digit1,
            digit2 => digit2,
            digit3 => digit3,
            an => an,
            seg => seg
        );

    -- Registro de estado (sincrónico)
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= CONFIG;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Lógica de siguiente estado (combinacional)
    process(current_state, btn_config_edge, btn_center_edge, key_correct, 
            key_incorrect, max_attempts, lockout_active)
    begin
        -- Valores por defecto
        next_state <= current_state;
        config_mode <= '0';
        reset_attempts <= '0';
        start_lockout <= '0';
        verify_key_signal <= '0';
        
        case current_state is
            when CONFIG =>
                config_mode <= '1';
                if btn_center_edge = '1' then
                    -- Guardar clave y pasar a VERIFY
                    next_state <= VERIFY;
                    reset_attempts <= '1';
                end if;
            
            when VERIFY =>
                if btn_config_edge = '1' then
                    -- Volver a CONFIG
                    next_state <= CONFIG;
                    
                elsif lockout_active = '1' then
                    -- Si el lockout está activo, ir a LOCKED
                    next_state <= LOCKED;
                    
                elsif btn_center_edge = '1' then
                    -- Verificar clave cuando se presiona el botón
                    verify_key_signal <= '1';
                    
                elsif key_correct = '1' then
                    -- Clave correcta -> UNLOCKED
                    next_state <= UNLOCKED;
                    
                elsif key_incorrect = '1' then
                    if max_attempts = '1' then
                        -- Último intento fallido -> LOCKED
                        start_lockout <= '1';
                        next_state <= LOCKED;
                    else
                        -- Intento fallido pero quedan más -> VERIFY
                        next_state <= VERIFY;
                    end if;
                end if;
            
            when LOCKED =>
                if lockout_active = '0' then
                    -- Bloqueo terminado -> VERIFY
                    next_state <= VERIFY;
                    reset_attempts <= '1';
                end if;
            
            when UNLOCKED =>
                if btn_config_edge = '1' then
                    -- Volver a CONFIG
                    next_state <= CONFIG;
                end if;
        end case;
    end process;

    -- Lógica de visualización
    process(current_state, sw, attempts_left, bcd_tens, bcd_ones)
    begin
        case current_state is
            when CONFIG =>
                -- Mostrar clave que se está configurando
                digit0 <= sw;
                digit1 <= "1100"; -- C de Config
                digit2 <= "0000";
                digit3 <= "0000";
                
            when VERIFY =>
                -- Mostrar intentos restantes
                digit0 <= sw;
                digit1 <= "0000";
                digit2 <= "00" & attempts_left;
                digit3 <= "0000";
                
            when LOCKED =>
                -- Mostrar cuenta regresiva
                digit0 <= bcd_ones;
                digit1 <= bcd_tens;
                digit2 <= "1111"; -- Apagado
                digit3 <= "1111"; -- Apagado
                
            when UNLOCKED =>
                -- Mostrar OK
                digit0 <= "1111";
                digit1 <= "1111";
                digit2 <= "1010"; -- A (ok)
                digit3 <= "0000"; -- O (ok)
                
            when others =>
                digit0 <= "1111";
                digit1 <= "1111";
                digit2 <= "1111";
                digit3 <= "1111";
        end case;
    end process;

    -- Control de LEDs
    process(current_state, attempts_left, clk_1hz)
    begin
        led <= "0000"; -- Por defecto apagados
        
        case current_state is
            when CONFIG =>
                led(3) <= '1'; -- LED3 encendido en modo config
                
            when VERIFY =>
                -- Mostrar intentos restantes
                case attempts_left is
                    when "11" => led(2 downto 0) <= "111"; -- 3 intentos
                    when "10" => led(2 downto 0) <= "011"; -- 2 intentos
                    when "01" => led(2 downto 0) <= "001"; -- 1 intento
                    when "00" => led(2 downto 0) <= "000"; -- 0 intentos
                    when others => led(2 downto 0) <= "000";
                end case;
                
            when LOCKED =>
                -- Parpadeo durante bloqueo
                if clk_1hz = '1' then
                    led <= "1111";
                else
                    led <= "0000";
                end if;
                
            when UNLOCKED =>
                led <= "1111"; -- Todos encendidos
                
            when others =>
                led <= "0000";
        end case;
    end process;

end Behavioral;