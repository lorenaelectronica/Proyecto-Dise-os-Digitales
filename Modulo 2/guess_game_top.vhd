library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity guess_game_top is
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        btn_guess : in STD_LOGIC;
        sw : in STD_LOGIC_VECTOR(3 downto 0);
        led : out STD_LOGIC_VECTOR(4 downto 0);
        an : out STD_LOGIC_VECTOR(3 downto 0);
        seg : out STD_LOGIC_VECTOR(6 downto 0)
    );
end guess_game_top;

architecture Behavioral of guess_game_top is
    -- Estados de la FSM
    type state_type is (IDLE, PLAYING, CORRECT, FAIL_DISPLAY, LOCKED);
    signal current_state : state_type := IDLE;
    
    -- Señales internas
    signal clk_1hz : STD_LOGIC;
    signal btn_stable : STD_LOGIC;
    signal btn_edge : STD_LOGIC;
    signal target_number : unsigned(3 downto 0);
    signal capture_random : STD_LOGIC := '0';
    signal attempts_left : integer range 0 to 5;
    signal reset_attempts : STD_LOGIC := '0';
    signal decrement_attempts : STD_LOGIC := '0';
    signal max_attempts_reached : STD_LOGIC;
    signal compare_enable : STD_LOGIC := '0';
    signal result_lower, result_higher, result_equal : STD_LOGIC;
    signal start_fail_timer, start_lockout_timer : STD_LOGIC := '0';
    signal fail_time, lockout_time : integer;
    signal fail_timer_done, lockout_timer_done : STD_LOGIC;
    
    -- Señales para displays
    signal digit0, digit1, digit2, digit3 : STD_LOGIC_VECTOR(3 downto 0);
    signal display_mode : STD_LOGIC_VECTOR(1 downto 0);
    signal special_char0, special_char1 : character;
    
    -- Declaración de componentes
    component clock_divider_1hz
        Generic (MAX_COUNT : integer := 50000000);
        Port (clk, reset : in STD_LOGIC; clk_1hz : out STD_LOGIC);
    end component;
    
    component lfsr_random
        Port (clk, reset, capture : in STD_LOGIC; random_number : out unsigned(3 downto 0));
    end component;
    
    component debouncer
        Generic (DEBOUNCE_TIME : integer := 1000000);
        Port (clk, reset, button_in : in STD_LOGIC; button_out : out STD_LOGIC);
    end component;
    
    component edge_detector
        Port (clk, reset, signal_in : in STD_LOGIC; edge_detected : out STD_LOGIC);
    end component;
    
    component attempt_counter
        Generic (MAX_ATTEMPTS : integer := 5);
        Port (clk, reset, reset_attempts, decrement : in STD_LOGIC;
              attempts_left : out integer range 0 to 5; max_reached : out STD_LOGIC);
    end component;
    
    component number_comparator
        Port (clk, reset, compare_enable : in STD_LOGIC;
              user_number, target_number : in unsigned(3 downto 0);
              result_lower, result_higher, result_equal : out STD_LOGIC);
    end component;
    
    component countdown_timer
        Generic (MAX_TIME : integer := 15);
        Port (clk, reset, clk_1hz, start_timer : in STD_LOGIC;
              time_remaining : out integer range 0 to 15; timer_done : out STD_LOGIC);
    end component;
    
    component seven_segment_driver
        Port (clk, reset : in STD_LOGIC;
              digit0, digit1, digit2, digit3 : in STD_LOGIC_VECTOR(3 downto 0);
              display_mode : in STD_LOGIC_VECTOR(1 downto 0);
              special_char0, special_char1 : in character;
              an : out STD_LOGIC_VECTOR(3 downto 0);
              seg : out STD_LOGIC_VECTOR(6 downto 0));
    end component;
    
begin
    -- Instanciación de submódulos
    U_CLK_DIV: clock_divider_1hz
        generic map (MAX_COUNT => 50000000)
        port map (clk => clk, reset => reset, clk_1hz => clk_1hz);
    
    U_LFSR: lfsr_random
        port map (clk => clk, reset => reset, capture => capture_random, random_number => target_number);
    
    U_DEBOUNCER: debouncer
        generic map (DEBOUNCE_TIME => 1000000)
        port map (clk => clk, reset => reset, button_in => btn_guess, button_out => btn_stable);
    
    U_EDGE: edge_detector
        port map (clk => clk, reset => reset, signal_in => btn_stable, edge_detected => btn_edge);
    
    U_ATTEMPTS: attempt_counter
        generic map (MAX_ATTEMPTS => 5)
        port map (clk => clk, reset => reset, reset_attempts => reset_attempts,
                  decrement => decrement_attempts, attempts_left => attempts_left,
                  max_reached => max_attempts_reached);
    
    U_COMPARATOR: number_comparator
        port map (clk => clk, reset => reset, compare_enable => compare_enable,
                  user_number => unsigned(sw), target_number => target_number,
                  result_lower => result_lower, result_higher => result_higher,
                  result_equal => result_equal);
    
    U_FAIL_TIMER: countdown_timer
        generic map (MAX_TIME => 3)
        port map (clk => clk, reset => reset, clk_1hz => clk_1hz,
                  start_timer => start_fail_timer, time_remaining => fail_time,
                  timer_done => fail_timer_done);
    
    U_LOCKOUT_TIMER: countdown_timer
        generic map (MAX_TIME => 15)
        port map (clk => clk, reset => reset, clk_1hz => clk_1hz,
                  start_timer => start_lockout_timer, time_remaining => lockout_time,
                  timer_done => lockout_timer_done);
    
    U_DISPLAY: seven_segment_driver
        port map (clk => clk, reset => reset,
                  digit0 => digit0, digit1 => digit1, digit2 => digit2, digit3 => digit3,
                  display_mode => display_mode,
                  special_char0 => special_char0, special_char1 => special_char1,
                  an => an, seg => seg);
    
    -- Máquina de estados principal
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
            capture_random <= '0';
            reset_attempts <= '1';
            compare_enable <= '0';
            decrement_attempts <= '0';
            start_fail_timer <= '0';
            start_lockout_timer <= '0';
        elsif rising_edge(clk) then
            -- Pulsos de un ciclo
            capture_random <= '0';
            reset_attempts <= '0';
            compare_enable <= '0';
            decrement_attempts <= '0';
            start_fail_timer <= '0';
            start_lockout_timer <= '0';
            
            case current_state is
                when IDLE =>
                    if btn_edge = '1' then
                        capture_random <= '1';
                        reset_attempts <= '1';
                        current_state <= PLAYING;
                    end if;
                
                when PLAYING =>
                    if btn_edge = '1' then
                        compare_enable <= '1';
                    end if;
                    
                    -- Procesar resultados de comparación
                    if result_equal = '1' then
                        current_state <= CORRECT;
                    elsif result_lower = '1' or result_higher = '1' then
                        decrement_attempts <= '1';
                        if max_attempts_reached = '1' then
                            start_fail_timer <= '1';
                            current_state <= FAIL_DISPLAY;
                        end if;
                    end if;
                
                when CORRECT =>
                    if btn_edge = '1' then
                        current_state <= IDLE;
                    end if;
                
                when FAIL_DISPLAY =>
                    if fail_timer_done = '1' then
                        start_lockout_timer <= '1';
                        current_state <= LOCKED;
                    end if;
                
                when LOCKED =>
                    if lockout_timer_done = '1' then
                        current_state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
    
    -- Lógica de LEDs
    process(current_state, attempts_left, clk_1hz)
    begin
        led <= "00000";
        case current_state is
            when IDLE | PLAYING =>
                case attempts_left is
                    when 5 => led <= "11111";
                    when 4 => led <= "01111";
                    when 3 => led <= "00111";
                    when 2 => led <= "00011";
                    when 1 => led <= "00001";
                    when others => led <= "00000";
                end case;
            when CORRECT =>
                led <= "11111";
            when FAIL_DISPLAY =>
                if clk_1hz = '1' then led <= "11111"; else led <= "00000"; end if;
            when LOCKED =>
                led <= "00000";
        end case;
    end process;
    
    -- Lógica de displays
    process(current_state, sw, result_lower, result_higher, lockout_time)
        variable tens, ones : integer;
    begin
        digit0 <= "1111";
        digit1 <= "1111";
        digit2 <= "1111";
        digit3 <= "1111";
        display_mode <= "00";
        special_char0 <= '-';
        special_char1 <= '-';
        
        case current_state is
            when IDLE =>
                display_mode <= "00";
                digit0 <= "1111";
                digit1 <= "1111";
                digit2 <= "1111";
                digit3 <= "1111";
            
            when PLAYING =>
                if result_lower = '1' then
                    display_mode <= "01"; -- SUBE
                elsif result_higher = '1' then
                    display_mode <= "10"; -- BAJA
                else
                    display_mode <= "00";
                    digit0 <= sw;
                end if;
            
            when CORRECT =>
                display_mode <= "11";
                special_char0 <= 'H';
                special_char1 <= 'O';
            
            when FAIL_DISPLAY =>
                display_mode <= "11";
                digit3 <= "1001"; -- F
                digit2 <= "1010"; -- A
                digit1 <= "1011"; -- I
                digit0 <= "1100"; -- L
                special_char0 <= 'L';
                special_char1 <= 'I';
            
            when LOCKED =>
                tens := lockout_time / 10;
                ones := lockout_time mod 10;
                display_mode <= "00";
                digit1 <= std_logic_vector(to_unsigned(tens, 4));
                digit0 <= std_logic_vector(to_unsigned(ones, 4));
        end case;
    end process;
    
end Behavioral;
