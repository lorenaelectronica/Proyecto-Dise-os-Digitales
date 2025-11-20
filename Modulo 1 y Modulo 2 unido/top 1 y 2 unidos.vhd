library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =====================================================
-- SISTEMA INTEGRADO: Seguridad + Juego
-- =====================================================
-- Flujo: CONFIG -> VERIFY -> UNLOCKED -> GAME
-- Módulo 1: Sistema de seguridad (configurar/verificar clave)
-- Módulo 2: Juego de adivinar número (se activa tras clave correcta)
-- =====================================================

entity integrated_system_top is
    Port ( 
        clk : in STD_LOGIC;                      -- 100 MHz
        reset : in STD_LOGIC;                     -- Reset general
        -- Botones
        btn_config : in STD_LOGIC;                -- BTNL - Modo configuración
        btn_center : in STD_LOGIC;                -- BTNC - Confirmar/Verificar/Adivinar
        -- Switches
        sw : in STD_LOGIC_VECTOR(3 downto 0);     -- Entrada de clave/número
        -- LEDs
        led : out STD_LOGIC_VECTOR(4 downto 0);   -- LEDs indicadores
        -- Display 7 segmentos
        an : out STD_LOGIC_VECTOR(3 downto 0);    -- Ánodos
        seg : out STD_LOGIC_VECTOR(6 downto 0)    -- Segmentos
    );
end integrated_system_top;

architecture Behavioral of integrated_system_top is

    -- ========== DECLARACIÓN DE COMPONENTES ==========
    
    -- Componentes del Módulo 1 (Sistema de Seguridad)
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

    -- ========== CONSTANTES DEL JUEGO ==========
    constant MAX_GAME_ATTEMPTS : integer := 5;
    constant GAME_LOCKOUT_TIME : integer := 15;
    constant FAIL_DISPLAY_TIME : integer := 3;
    
    -- ========== TIPOS ==========
    type main_state_type is (SECURITY_MODE, GAME_MODE);
    type security_state_type is (CONFIG, VERIFY, LOCKED, UNLOCKED);
    type game_state_type is (GAME_IDLE, GAME_PLAYING, GAME_CORRECT, GAME_FAIL_DISPLAY, GAME_LOCKED);
    type comparison_type is (NONE, LOWER, HIGHER, EQUAL);
    
    -- ========== SEÑALES DE CONTROL PRINCIPAL ==========
    signal main_state : main_state_type := SECURITY_MODE;
    signal security_state : security_state_type := CONFIG;
    signal game_state : game_state_type := GAME_IDLE;
    
    -- ========== SEÑALES DEL MÓDULO DE SEGURIDAD ==========
    signal clk_1hz : STD_LOGIC;
    signal btn_config_db, btn_center_db : STD_LOGIC;
    signal btn_config_edge, btn_center_edge : STD_LOGIC;
    signal stored_key : STD_LOGIC_VECTOR(3 downto 0);
    signal key_correct, key_incorrect : STD_LOGIC;
    signal attempts_left : STD_LOGIC_VECTOR(1 downto 0);
    signal max_attempts : STD_LOGIC;
    signal lockout_active : STD_LOGIC;
    signal time_remaining : STD_LOGIC_VECTOR(5 downto 0);
    signal bcd_tens, bcd_ones : STD_LOGIC_VECTOR(3 downto 0);
    signal reset_attempts : STD_LOGIC := '0';
    signal start_lockout : STD_LOGIC := '0';
    signal config_mode : STD_LOGIC := '0';
    signal verify_key_signal : STD_LOGIC := '0';
    
    -- ========== SEÑALES DEL JUEGO ==========
    signal target_number : unsigned(3 downto 0) := "0000";
    signal lfsr : unsigned(15 downto 0) := "1010110011100001";
    signal new_game : STD_LOGIC := '0';
    signal game_attempts_left : integer range 0 to MAX_GAME_ATTEMPTS := MAX_GAME_ATTEMPTS;
    signal comparison : comparison_type := NONE;
    signal game_countdown : integer range 0 to GAME_LOCKOUT_TIME := 0;
    signal fail_timer : integer range 0 to FAIL_DISPLAY_TIME := 0;
    signal clk_1hz_prev : STD_LOGIC := '0';
    
    -- ========== SEÑALES DE DISPLAY ==========
    signal digit0, digit1, digit2, digit3 : STD_LOGIC_VECTOR(3 downto 0);
    signal refresh_counter : unsigned(16 downto 0) := (others => '0');
    signal digit_select : STD_LOGIC_VECTOR(1 downto 0);
    signal current_digit : STD_LOGIC_VECTOR(3 downto 0);
    
    -- ========== FUNCIONES DE DECODIFICACIÓN ==========
    function hex_to_7seg(hex : STD_LOGIC_VECTOR(3 downto 0)) return STD_LOGIC_VECTOR is
        variable segments : STD_LOGIC_VECTOR(6 downto 0);
    begin
        case hex is
            when "0000" => segments := "1000000"; -- 0
            when "0001" => segments := "1111001"; -- 1
            when "0010" => segments := "0100100"; -- 2
            when "0011" => segments := "0110000"; -- 3
            when "0100" => segments := "0011001"; -- 4
            when "0101" => segments := "0010010"; -- 5
            when "0110" => segments := "0000010"; -- 6
            when "0111" => segments := "1111000"; -- 7
            when "1000" => segments := "0000000"; -- 8
            when "1001" => segments := "0010000"; -- 9
            when "1010" => segments := "0001000"; -- A
            when "1011" => segments := "0000011"; -- B
            when "1100" => segments := "1000110"; -- C
            when "1101" => segments := "0100001"; -- D
            when "1110" => segments := "0000110"; -- E
            when "1111" => segments := "1111110"; -- -
            when others => segments := "1111111";
        end case;
        return segments;
    end function;
    
    function char_to_7seg(char : character) return STD_LOGIC_VECTOR is
        variable segments : STD_LOGIC_VECTOR(6 downto 0);
    begin
        case char is
            when 'S' => segments := "0010010";
            when 'U' => segments := "1000001";
            when 'B' => segments := "0000011";
            when 'E' => segments := "0000110";
            when 'A' => segments := "0001000";
            when 'J' => segments := "1100001";
            when 'F' => segments := "0001110";
            when 'I' => segments := "1111001";
            when 'L' => segments := "1000111";
            when 'O' => segments := "1000000";
            when 'H' => segments := "0001001";
            when '-' => segments := "1111111";
            when others => segments := "1111111";
        end case;
        return segments;
    end function;

begin

    -- ========== INSTANCIAS DEL MÓDULO DE SEGURIDAD ==========
    
    clk_div: clock_divider
        port map (
            clk => clk,
            reset => reset,
            clk_1hz => clk_1hz
        );
    
    db_config: debouncer
        generic map ( DEBOUNCE_TIME => 1000000 )
        port map (
            clk => clk,
            reset => reset,
            button_in => btn_config,
            button_out => btn_config_db
        );
    
    db_center: debouncer
        generic map ( DEBOUNCE_TIME => 1000000 )
        port map (
            clk => clk,
            reset => reset,
            button_in => btn_center,
            button_out => btn_center_db
        );
    
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
    
    key_store: key_storage
        port map (
            clk => clk,
            reset => reset,
            config_mode => config_mode,
            save_key => btn_center_edge,
            new_key => sw,
            stored_key => stored_key
        );
    
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
    
    attempt_cnt: attempt_counter
        port map (
            clk => clk,
            reset => reset,
            failed_attempt => key_incorrect,
            reset_attempts => reset_attempts,
            attempts_left => attempts_left,
            max_attempts_reached => max_attempts
        );
    
    lockout_tmr: lockout_timer
        port map (
            clk => clk,
            reset => reset,
            clk_1hz => clk_1hz,
            start_lockout => start_lockout,
            lockout_active => lockout_active,
            time_remaining => time_remaining
        );
    
    bcd_conv: bcd_converter
        port map (
            binary_in => time_remaining,
            tens => bcd_tens,
            ones => bcd_ones
        );

    -- ========== LFSR PARA NÚMERO ALEATORIO ==========
    process(clk, reset)
        variable feedback : STD_LOGIC;
    begin
        if reset = '1' then
            lfsr <= "1010110011100001";
        elsif rising_edge(clk) then
            feedback := lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10);
            lfsr <= lfsr(14 downto 0) & feedback;
            
            if new_game = '1' then
                target_number <= lfsr(3 downto 0);
            end if;
        end if;
    end process;

    -- ========== MÁQUINA DE ESTADOS PRINCIPAL ==========
    process(clk, reset)
        variable user_guess : unsigned(3 downto 0);
        variable clk_1hz_edge : STD_LOGIC;
    begin
        if reset = '1' then
            main_state <= SECURITY_MODE;
            security_state <= CONFIG;
            game_state <= GAME_IDLE;
            reset_attempts <= '0';
            start_lockout <= '0';
            config_mode <= '0';
            verify_key_signal <= '0';
            new_game <= '0';
            game_attempts_left <= MAX_GAME_ATTEMPTS;
            comparison <= NONE;
            game_countdown <= 0;
            fail_timer <= 0;
            clk_1hz_prev <= '0';
            
        elsif rising_edge(clk) then
            -- Valores por defecto
            reset_attempts <= '0';
            start_lockout <= '0';
            config_mode <= '0';
            verify_key_signal <= '0';
            new_game <= '0';
            
            -- Detectar flanco de clk_1hz
            clk_1hz_edge := clk_1hz and not clk_1hz_prev;
            clk_1hz_prev <= clk_1hz;
            
            -- ========== MODO SEGURIDAD ==========
            if main_state = SECURITY_MODE then
                case security_state is
                    when CONFIG =>
                        config_mode <= '1';
                        if btn_center_edge = '1' then
                            security_state <= VERIFY;
                            reset_attempts <= '1';
                        end if;
                    
                    when VERIFY =>
                        if btn_config_edge = '1' then
                            security_state <= CONFIG;
                        elsif lockout_active = '1' then
                            security_state <= LOCKED;
                        elsif btn_center_edge = '1' then
                            verify_key_signal <= '1';
                        elsif key_correct = '1' then
                            security_state <= UNLOCKED;
                        elsif key_incorrect = '1' then
                            if max_attempts = '1' then
                                start_lockout <= '1';
                                security_state <= LOCKED;
                            end if;
                        end if;
                    
                    when LOCKED =>
                        if lockout_active = '0' then
                            security_state <= VERIFY;
                            reset_attempts <= '1';
                        end if;
                    
                    when UNLOCKED =>
                        -- Transición automática al juego después de 1 segundo
                        if clk_1hz_edge = '1' then
                            main_state <= GAME_MODE;
                            game_state <= GAME_IDLE;
                            game_attempts_left <= MAX_GAME_ATTEMPTS;
                            comparison <= NONE;
                        end if;
                end case;
                
            -- ========== MODO JUEGO ==========
            elsif main_state = GAME_MODE then
                case game_state is
                    when GAME_IDLE =>
                        game_attempts_left <= MAX_GAME_ATTEMPTS;
                        comparison <= NONE;
                        game_countdown <= 0;
                        fail_timer <= 0;
                        if btn_center_edge = '1' then
                            new_game <= '1';
                            game_state <= GAME_PLAYING;
                        end if;
                        -- Regresar al modo seguridad con btn_config
                        if btn_config_edge = '1' then
                            main_state <= SECURITY_MODE;
                            security_state <= CONFIG;
                        end if;
                    
                    when GAME_PLAYING =>
                        if btn_center_edge = '1' then
                            user_guess := unsigned(sw);
                            
                            if user_guess = target_number then
                                comparison <= EQUAL;
                                game_state <= GAME_CORRECT;
                            elsif user_guess < target_number then
                                comparison <= LOWER;
                                game_attempts_left <= game_attempts_left - 1;
                                if game_attempts_left - 1 = 0 then
                                    game_state <= GAME_FAIL_DISPLAY;
                                    fail_timer <= FAIL_DISPLAY_TIME;
                                end if;
                            else
                                comparison <= HIGHER;
                                game_attempts_left <= game_attempts_left - 1;
                                if game_attempts_left - 1 = 0 then
                                    game_state <= GAME_FAIL_DISPLAY;
                                    fail_timer <= FAIL_DISPLAY_TIME;
                                end if;
                            end if;
                        end if;
                    
                    when GAME_CORRECT =>
                        if btn_center_edge = '1' then
                            game_state <= GAME_IDLE;
                        end if;
                    
                    when GAME_FAIL_DISPLAY =>
                        if clk_1hz_edge = '1' then
                            if fail_timer > 0 then
                                fail_timer <= fail_timer - 1;
                            end if;
                        end if;
                        if fail_timer = 0 then
                            game_state <= GAME_LOCKED;
                            game_countdown <= GAME_LOCKOUT_TIME;
                        end if;
                    
                    when GAME_LOCKED =>
                        if clk_1hz_edge = '1' then
                            if game_countdown > 0 then
                                game_countdown <= game_countdown - 1;
                            end if;
                        end if;
                        if game_countdown = 0 then
                            game_state <= GAME_IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- ========== LÓGICA DE DISPLAYS ==========
    process(main_state, security_state, game_state, sw, attempts_left, 
            bcd_tens, bcd_ones, comparison, game_countdown)
        variable tens, ones : integer;
    begin
        if main_state = SECURITY_MODE then
            case security_state is
                when CONFIG =>
                    digit0 <= sw;
                    digit1 <= "1100"; -- C
                    digit2 <= "0000";
                    digit3 <= "0000";
                
                when VERIFY =>
                    digit0 <= sw;
                    digit1 <= "0000";
                    digit2 <= "00" & attempts_left;
                    digit3 <= "0000";
                
                when LOCKED =>
                    digit0 <= bcd_ones;
                    digit1 <= bcd_tens;
                    digit2 <= "1111";
                    digit3 <= "1111";
                
                when UNLOCKED =>
                    digit0 <= "1111";
                    digit1 <= "1111";
                    digit2 <= "1010"; -- A
                    digit3 <= "0000"; -- O
            end case;
            
        elsif main_state = GAME_MODE then
            case game_state is
                when GAME_IDLE =>
                    digit3 <= "1111";
                    digit2 <= "1111";
                    digit1 <= "1111";
                    digit0 <= "1111";
                
                when GAME_PLAYING =>
                    if comparison = LOWER then
                        digit3 <= "0001"; -- S
                        digit2 <= "0010"; -- U
                        digit1 <= "0011"; -- B
                        digit0 <= "0100"; -- E
                    elsif comparison = HIGHER then
                        digit3 <= "0101"; -- B
                        digit2 <= "0110"; -- A
                        digit1 <= "0111"; -- J
                        digit0 <= "0110"; -- A
                    else
                        digit3 <= "1111";
                        digit2 <= "1111";
                        digit1 <= "1111";
                        digit0 <= sw;
                    end if;
                
                when GAME_CORRECT =>
                    digit3 <= "1111";
                    digit2 <= "1111";
                    digit1 <= "0000"; -- O
                    digit0 <= "1000"; -- H
                
                when GAME_FAIL_DISPLAY =>
                    digit3 <= "1001"; -- F
                    digit2 <= "1010"; -- A
                    digit1 <= "1011"; -- I
                    digit0 <= "1100"; -- L
                
                when GAME_LOCKED =>
                    tens := game_countdown / 10;
                    ones := game_countdown mod 10;
                    digit3 <= "1111";
                    digit2 <= "1111";
                    digit1 <= std_logic_vector(to_unsigned(tens, 4));
                    digit0 <= std_logic_vector(to_unsigned(ones, 4));
            end case;
        end if;
    end process;

    -- ========== CONTROL DE LEDs ==========
    process(main_state, security_state, game_state, attempts_left, 
            game_attempts_left, clk_1hz)
    begin
        led <= "00000";
        
        if main_state = SECURITY_MODE then
            case security_state is
                when CONFIG =>
                    led(4) <= '1';
                
                when VERIFY =>
                    case attempts_left is
                        when "11" => led(2 downto 0) <= "111";
                        when "10" => led(2 downto 0) <= "011";
                        when "01" => led(2 downto 0) <= "001";
                        when "00" => led(2 downto 0) <= "000";
                        when others => led(2 downto 0) <= "000";
                    end case;
                
                when LOCKED =>
                    if clk_1hz = '1' then
                        led <= "11111";
                    else
                        led <= "00000";
                    end if;
                
                when UNLOCKED =>
                    led <= "11111";
            end case;
            
        elsif main_state = GAME_MODE then
            case game_state is
                when GAME_IDLE | GAME_PLAYING =>
                    case game_attempts_left is
                        when 5 => led <= "11111";
                        when 4 => led <= "01111";
                        when 3 => led <= "00111";
                        when 2 => led <= "00011";
                        when 1 => led <= "00001";
                        when 0 => led <= "00000";
                        when others => led <= "00000";
                    end case;
                
                when GAME_CORRECT =>
                    led <= "11111";
                
                when GAME_FAIL_DISPLAY =>
                    if clk_1hz = '1' then
                        led <= "11111";
                    else
                        led <= "00000";
                    end if;
                
                when GAME_LOCKED =>
                    led <= "00000";
            end case;
        end if;
    end process;

    -- ========== MULTIPLEXACIÓN DE DISPLAYS ==========
    process(clk, reset)
    begin
        if reset = '1' then
            refresh_counter <= (others => '0');
        elsif rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;
    
    digit_select <= std_logic_vector(refresh_counter(16 downto 15));
    
    process(digit_select, digit0, digit1, digit2, digit3)
    begin
        case digit_select is
            when "00" =>
                an <= "1110";
                current_digit <= digit0;
            when "01" =>
                an <= "1101";
                current_digit <= digit1;
            when "10" =>
                an <= "1011";
                current_digit <= digit2;
            when "11" =>
                an <= "0111";
                current_digit <= digit3;
            when others =>
                an <= "1111";
                current_digit <= "0000";
        end case;
    end process;

    -- ========== DECODIFICACIÓN A 7 SEGMENTOS ==========
    process(current_digit, main_state, game_state, digit0, digit1, digit2, digit3)
    begin
        if main_state = GAME_MODE and game_state = GAME_PLAYING then
            if (digit3 = "0001" and digit2 = "0010" and digit1 = "0011" and digit0 = "0100") or
               (digit3 = "0101" and digit2 = "0110" and digit1 = "0111" and digit0 = "0110") then
                case current_digit is
                    when "0001" => seg <= char_to_7seg('S');
                    when "0010" => seg <= char_to_7seg('U');
                    when "0011" => seg <= char_to_7seg('B');
                    when "0100" => seg <= char_to_7seg('E');
                    when "0101" => seg <= char_to_7seg('B');
                    when "0110" => seg <= char_to_7seg('A');
                    when "0111" => seg <= char_to_7seg('J');
                    when others => seg <= hex_to_7seg(current_digit);
                end case;
            else
                seg <= hex_to_7seg(current_digit);
            end if;
        elsif main_state = GAME_MODE and game_state = GAME_CORRECT then
            case current_digit is
                when "0000" => seg <= char_to_7seg('O');
                when "1000" => seg <= char_to_7seg('H');
                when others => seg <= char_to_7seg('-');
            end case;
        elsif main_state = GAME_MODE and game_state = GAME_FAIL_DISPLAY then
            case current_digit is
                when "1001" => seg <= char_to_7seg('F');
                when "1010" => seg <= char_to_7seg('A');
                when "1011" => seg <= char_to_7seg('I');
                when "1100" => seg <= char_to_7seg('L');
                when others => seg <= char_to_7seg('-');
            end case;
        else
            seg <= hex_to_7seg(current_digit);
        end if;
    end process;

end Behavioral;
