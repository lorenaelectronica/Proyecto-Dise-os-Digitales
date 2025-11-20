library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =====================================================
-- Módulo 2: Juego "Adivina el Número"
-- VERSIÓN FINAL PARA HARDWARE - BASYS 3
-- =====================================================
-- Características:
-- - Número aleatorio de 4 bits (0-15)
-- - 5 intentos por ronda
-- - Retroalimentación: SUBE/BAJA/OH
-- - Bloqueo de 15 segundos tras 5 fallos
-- - Display FAIL por 3 segundos
-- - LEDs muestran intentos restantes
-- =====================================================

entity guess_game is
    Port ( 
        clk : in STD_LOGIC;                      -- 100 MHz
        reset : in STD_LOGIC;                     -- Reset (BTNU)
        btn_guess : in STD_LOGIC;                 -- Botón para adivinar (BTNC)
        sw : in STD_LOGIC_VECTOR(3 downto 0);     -- Entrada del número (SW3-SW0)
        led : out STD_LOGIC_VECTOR(4 downto 0);   -- Intentos restantes (LED4-LED0)
        an : out STD_LOGIC_VECTOR(3 downto 0);    -- Ánodos displays
        seg : out STD_LOGIC_VECTOR(6 downto 0)    -- Segmentos displays
    );
end guess_game;

architecture Behavioral of guess_game is

    -- ========== CONSTANTES ==========
    constant MAX_ATTEMPTS : integer := 5;
    constant LOCKOUT_TIME : integer := 15;        -- 15 segundos
    constant FAIL_DISPLAY_TIME : integer := 3;    -- 3 segundos
    
    -- ========== TIPOS ==========
    type state_type is (IDLE, PLAYING, CORRECT, FAIL_DISPLAY, LOCKED);
    type comparison_type is (NONE, LOWER, HIGHER, EQUAL);
    
    -- ========== SEÑALES DE ESTADO ==========
    signal current_state : state_type := IDLE;
    signal comparison : comparison_type := NONE;
    
    -- ========== NÚMERO OBJETIVO Y LFSR ==========
    signal target_number : unsigned(3 downto 0) := "0000";
    signal lfsr : unsigned(15 downto 0) := "1010110011100001"; -- Semilla inicial
    signal new_game : STD_LOGIC := '0';
    
    -- ========== CONTADOR DE INTENTOS ==========
    signal attempts_left : integer range 0 to MAX_ATTEMPTS := MAX_ATTEMPTS;
    
    -- ========== TEMPORIZADORES ==========
    signal clk_1hz : STD_LOGIC := '0';
    signal clk_1hz_prev : STD_LOGIC := '0'; -- Para detectar flancos
    signal counter_1hz : integer range 0 to 100000000 := 0; -- HARDWARE: 100 MHz
    signal countdown : integer range 0 to LOCKOUT_TIME := 0;
    signal fail_timer : integer range 0 to FAIL_DISPLAY_TIME := 0;
    
    -- ========== ANTI-REBOTE Y DETECCIÓN DE FLANCO ==========
    signal btn_sync : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal btn_stable : STD_LOGIC := '0';
    signal btn_edge : STD_LOGIC := '0';
    signal debounce_counter : integer range 0 to 1000000 := 0; -- HARDWARE: 10ms
    
    -- ========== DISPLAYS 7 SEGMENTOS ==========
    signal digit0, digit1, digit2, digit3 : STD_LOGIC_VECTOR(3 downto 0);
    signal refresh_counter : unsigned(16 downto 0) := (others => '0');
    signal digit_select : STD_LOGIC_VECTOR(1 downto 0);
    signal current_digit : STD_LOGIC_VECTOR(3 downto 0);
    
    -- ========== FUNCIÓN: HEXADECIMAL A 7 SEGMENTOS ==========
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
            when "1011" => segments := "0000011"; -- b
            when "1100" => segments := "1000110"; -- C
            when "1101" => segments := "0100001"; -- d
            when "1110" => segments := "0000110"; -- E
            when "1111" => segments := "1111111"; -- Apagado (-)
            when others => segments := "1111111";
        end case;
        return segments;
    end function;
    
    -- ========== FUNCIÓN: CARACTERES ESPECIALES ==========
    function char_to_7seg(char : character) return STD_LOGIC_VECTOR is
        variable segments : STD_LOGIC_VECTOR(6 downto 0);
    begin
        case char is
            when 'S' => segments := "0010010"; -- S
            when 'U' => segments := "1000001"; -- U
            when 'B' => segments := "0000011"; -- b
            when 'E' => segments := "0000110"; -- E
            when 'A' => segments := "0001000"; -- A
            when 'J' => segments := "1100001"; -- J (aproximado)
            when 'F' => segments := "0001110"; -- F
            when 'I' => segments := "1111001"; -- I (como 1)
            when 'L' => segments := "1000111"; -- L
            when 'O' => segments := "1000000"; -- O (como 0)
            when 'H' => segments := "0001001"; -- H
            when '-' => segments := "1111111"; -- Apagado
            when others => segments := "1111111";
        end case;
        return segments;
    end function;

begin

    -- ========== GENERADOR DE RELOJ 1 HZ ==========
    process(clk, reset)
    begin
        if reset = '1' then
            counter_1hz <= 0;
            clk_1hz <= '0';
        elsif rising_edge(clk) then
            if counter_1hz = 50000000-1 then -- Medio segundo (100 MHz / 2)
                counter_1hz <= 0;
                clk_1hz <= not clk_1hz;
            else
                counter_1hz <= counter_1hz + 1;
            end if;
        end if;
    end process;
    
    -- ========== LFSR PARA NÚMERO PSEUDOALEATORIO ==========
    process(clk, reset)
        variable feedback : STD_LOGIC;
    begin
        if reset = '1' then
            lfsr <= "1010110011100001"; -- Reiniciar semilla
        elsif rising_edge(clk) then
            -- LFSR corre siempre para más aleatoriedad
            feedback := lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10);
            lfsr <= lfsr(14 downto 0) & feedback;
            
            if new_game = '1' then
                -- Capturar número del LFSR
                target_number <= lfsr(3 downto 0);
            end if;
        end if;
    end process;
    
    -- ========== ANTI-REBOTE DEL BOTÓN ==========
    process(clk, reset)
    begin
        if reset = '1' then
            btn_sync <= "000";
            btn_stable <= '0';
            debounce_counter <= 0;
        elsif rising_edge(clk) then
            -- Sincronización de 3 etapas
            btn_sync <= btn_sync(1 downto 0) & btn_guess;
            
            -- Anti-rebote con contador
            if btn_sync(2) /= btn_stable then
                if debounce_counter = 1000000-1 then -- ~10ms a 100 MHz
                    btn_stable <= btn_sync(2);
                    debounce_counter <= 0;
                else
                    debounce_counter <= debounce_counter + 1;
                end if;
            else
                debounce_counter <= 0;
            end if;
        end if;
    end process;
    
    -- ========== DETECTOR DE FLANCO ==========
    process(clk, reset)
        variable btn_prev : STD_LOGIC := '0';
    begin
        if reset = '1' then
            btn_edge <= '0';
            btn_prev := '0';
        elsif rising_edge(clk) then
            btn_edge <= btn_stable and not btn_prev;
            btn_prev := btn_stable;
        end if;
    end process;
    
    -- ========== MÁQUINA DE ESTADOS PRINCIPAL ==========
    process(clk, reset)
        variable user_guess : unsigned(3 downto 0);
        variable clk_1hz_edge : STD_LOGIC;
    begin
        if reset = '1' then
            current_state <= IDLE;
            attempts_left <= MAX_ATTEMPTS;
            comparison <= NONE;
            new_game <= '1';
            countdown <= 0;
            fail_timer <= 0;
            clk_1hz_prev <= '0';
        elsif rising_edge(clk) then
            new_game <= '0'; -- Pulso de un ciclo
            
            -- Detectar flanco ascendente de clk_1hz
            clk_1hz_edge := clk_1hz and not clk_1hz_prev;
            clk_1hz_prev <= clk_1hz;
            
            case current_state is
                -- ========== ESTADO: IDLE ==========
                when IDLE =>
                    attempts_left <= MAX_ATTEMPTS;
                    comparison <= NONE;
                    countdown <= 0;
                    fail_timer <= 0;
                    if btn_edge = '1' then
                        new_game <= '1'; -- Generar nuevo número
                        current_state <= PLAYING;
                    end if;
                
                -- ========== ESTADO: PLAYING ==========
                when PLAYING =>
                    if btn_edge = '1' then
                        user_guess := unsigned(sw);
                        
                        -- Comparar con el número objetivo
                        if user_guess = target_number then
                            comparison <= EQUAL;
                            current_state <= CORRECT;
                        elsif user_guess < target_number then
                            comparison <= LOWER;
                            attempts_left <= attempts_left - 1;
                            
                            if attempts_left - 1 = 0 then
                                current_state <= FAIL_DISPLAY;
                                fail_timer <= FAIL_DISPLAY_TIME;
                            end if;
                        else -- user_guess > target_number
                            comparison <= HIGHER;
                            attempts_left <= attempts_left - 1;
                            
                            if attempts_left - 1 = 0 then
                                current_state <= FAIL_DISPLAY;
                                fail_timer <= FAIL_DISPLAY_TIME;
                            end if;
                        end if;
                    end if;
                
                -- ========== ESTADO: CORRECT ==========
                when CORRECT =>
                    -- Mostrar "OH" indefinidamente
                    -- Presionar botón para nueva ronda
                    if btn_edge = '1' then
                        current_state <= IDLE;
                    end if;
                
                -- ========== ESTADO: FAIL_DISPLAY ==========
                when FAIL_DISPLAY =>
                    -- Mostrar "FAIL" por 3 segundos
                    -- Detectar flanco de clk_1hz para contar segundos
                    if clk_1hz_edge = '1' then
                        if fail_timer > 0 then
                            fail_timer <= fail_timer - 1;
                        end if;
                    end if;
                    
                    -- Cambiar a LOCKED cuando termine el timer
                    if fail_timer = 0 then
                        current_state <= LOCKED;
                        countdown <= LOCKOUT_TIME;
                    end if;
                
                -- ========== ESTADO: LOCKED ==========
                when LOCKED =>
                    -- Bloqueo de 15 segundos con cuenta regresiva
                    -- Detectar flanco de clk_1hz para contar segundos
                    if clk_1hz_edge = '1' then
                        if countdown > 0 then
                            countdown <= countdown - 1;
                        end if;
                    end if;
                    
                    -- Cambiar a IDLE cuando termine la cuenta
                    if countdown = 0 then
                        current_state <= IDLE;
                    end if;
                
                when others =>
                    current_state <= IDLE;
            end case;
        end if;
    end process;
    
    -- ========== CONTROL DE LEDs (INTENTOS RESTANTES) ==========
    process(current_state, attempts_left, clk_1hz)
    begin
        led <= "00000"; -- Por defecto apagados
        
        case current_state is
            when IDLE | PLAYING =>
                -- Mostrar intentos restantes
                case attempts_left is
                    when 5 => led <= "11111";
                    when 4 => led <= "01111";
                    when 3 => led <= "00111";
                    when 2 => led <= "00011";
                    when 1 => led <= "00001";
                    when 0 => led <= "00000";
                    when others => led <= "00000";
                end case;
            
            when CORRECT =>
                -- Todos encendidos cuando acierta
                led <= "11111";
            
            when FAIL_DISPLAY =>
                -- Parpadeo durante FAIL
                if clk_1hz = '1' then
                    led <= "11111";
                else
                    led <= "00000";
                end if;
            
            when LOCKED =>
                -- Apagados durante bloqueo
                led <= "00000";
        end case;
    end process;
    
    -- ========== LÓGICA DE DISPLAYS ==========
    process(current_state, comparison, countdown, sw)
        variable tens, ones : integer;
    begin
        case current_state is
            when IDLE =>
                -- Mostrar "----"
                digit3 <= "1111"; -- -
                digit2 <= "1111"; -- -
                digit1 <= "1111"; -- -
                digit0 <= "1111"; -- -
            
            when PLAYING =>
                -- Mostrar retroalimentación y número actual
                if comparison = LOWER then
                    -- "SUBE"
                    digit3 <= "0001"; -- S (codificado)
                    digit2 <= "0010"; -- U (codificado)
                    digit1 <= "0011"; -- B (codificado)
                    digit0 <= "0100"; -- E (codificado)
                elsif comparison = HIGHER then
                    -- "BAJA"
                    digit3 <= "0101"; -- B (codificado)
                    digit2 <= "0110"; -- A (codificado)
                    digit1 <= "0111"; -- J (codificado)
                    digit0 <= "0110"; -- A (codificado)
                else
                    -- Mostrar número ingresado actual
                    digit3 <= "1111"; -- -
                    digit2 <= "1111"; -- -
                    digit1 <= "1111"; -- -
                    digit0 <= sw;     -- Número actual
                end if;
            
            when CORRECT =>
                -- Mostrar "OH"
                digit3 <= "1111"; -- -
                digit2 <= "1111"; -- -
                digit1 <= "0000"; -- O
                digit0 <= "1000"; -- H (codificado)
            
            when FAIL_DISPLAY =>
                -- Mostrar "FAIL"
                digit3 <= "1001"; -- F (codificado)
                digit2 <= "1010"; -- A (codificado)
                digit1 <= "1011"; -- I (codificado)
                digit0 <= "1100"; -- L (codificado)
            
            when LOCKED =>
                -- Mostrar cuenta regresiva 15 a 0
                tens := countdown / 10;
                ones := countdown mod 10;
                digit3 <= "1111"; -- -
                digit2 <= "1111"; -- -
                digit1 <= std_logic_vector(to_unsigned(tens, 4));
                digit0 <= std_logic_vector(to_unsigned(ones, 4));
        end case;
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
    process(current_digit, current_state, digit0, digit1, digit2, digit3)
    begin
        -- Decodificación según el estado actual
        case current_state is
            when PLAYING =>
                -- Verificar si es un código especial para SUBE/BAJA
                if (digit3 = "0001" and digit2 = "0010" and digit1 = "0011" and digit0 = "0100") or
                   (digit3 = "0101" and digit2 = "0110" and digit1 = "0111" and digit0 = "0110") then
                    -- Es SUBE o BAJA, usar caracteres especiales
                    case current_digit is
                        when "0001" => seg <= char_to_7seg('S'); -- S
                        when "0010" => seg <= char_to_7seg('U'); -- U
                        when "0011" => seg <= char_to_7seg('B'); -- B
                        when "0100" => seg <= char_to_7seg('E'); -- E
                        when "0101" => seg <= char_to_7seg('B'); -- B
                        when "0110" => seg <= char_to_7seg('A'); -- A
                        when "0111" => seg <= char_to_7seg('J'); -- J
                        when others => seg <= hex_to_7seg(current_digit);
                    end case;
                else
                    -- Es número normal
                    seg <= hex_to_7seg(current_digit);
                end if;
            
            when CORRECT =>
                -- OH
                case current_digit is
                    when "0000" => seg <= char_to_7seg('O'); -- O
                    when "1000" => seg <= char_to_7seg('H'); -- H
                    when others => seg <= char_to_7seg('-');
                end case;
            
            when FAIL_DISPLAY =>
                -- FAIL
                case current_digit is
                    when "1001" => seg <= char_to_7seg('F'); -- F
                    when "1010" => seg <= char_to_7seg('A'); -- A
                    when "1011" => seg <= char_to_7seg('I'); -- I
                    when "1100" => seg <= char_to_7seg('L'); -- L
                    when others => seg <= char_to_7seg('-');
                end case;
            
            when others =>
                -- IDLE y LOCKED: usar decodificación normal
                seg <= hex_to_7seg(current_digit);
        end case;
    end process;

end Behavioral;