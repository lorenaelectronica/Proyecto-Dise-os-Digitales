library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_segment_driver is
    Port (
        clk : in STD_LOGIC;                         -- Reloj maestro
        reset : in STD_LOGIC;                       -- Reset asíncrono
        digit0 : in STD_LOGIC_VECTOR(3 downto 0);   -- Display derecho (AN0)
        digit1 : in STD_LOGIC_VECTOR(3 downto 0);   -- Display centro-derecha (AN1)
        digit2 : in STD_LOGIC_VECTOR(3 downto 0);   -- Display centro-izquierda (AN2)
        digit3 : in STD_LOGIC_VECTOR(3 downto 0);   -- Display izquierdo (AN3)
        display_mode : in STD_LOGIC_VECTOR(1 downto 0); -- Modo: 00=hex, 01=SUBE, 10=BAJA, 11=special
        special_char0 : in character;               -- Carácter especial para posición 0
        special_char1 : in character;               -- Carácter especial para posición 1
        an : out STD_LOGIC_VECTOR(3 downto 0);      -- Ánodos (activo bajo)
        seg : out STD_LOGIC_VECTOR(6 downto 0)      -- Segmentos a-g (activo bajo)
    );
end seven_segment_driver;

architecture Behavioral of seven_segment_driver is
    signal refresh_counter : unsigned(16 downto 0) := (others => '0');  -- Contador de refresco
    signal digit_select : STD_LOGIC_VECTOR(1 downto 0);  -- Selector de display actual (bits 16:15)
    signal current_digit : STD_LOGIC_VECTOR(3 downto 0); -- Dígito actualmente mostrado
    
    -- ========== FUNCIÓN: HEXADECIMAL A 7 SEGMENTOS ==========
    -- Convierte valores hexadecimales (0-F) a patrones de 7 segmentos
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
            when "1111" => segments := "1111111"; -- - (apagado)
            when others => segments := "1111111";
        end case;
        return segments;
    end function;
    
    -- ========== FUNCIÓN: CARACTERES ESPECIALES A 7 SEGMENTOS ==========
    -- Convierte letras especiales para mensajes (SUBE, BAJA, OH, FAIL)
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
    -- ========== CONTADOR DE REFRESCO ==========
    -- Genera señal de multiplexación a ~381 Hz
    process(clk, reset)
    begin
        if reset = '1' then
            refresh_counter <= (others => '0');
        elsif rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;  -- Incrementar continuamente
        end if;
    end process;
    
    -- Usar bits 16:15 como selector (cambia cada 655.36 us)
    digit_select <= std_logic_vector(refresh_counter(16 downto 15));
    
    -- ========== MULTIPLEXACIÓN DE DISPLAYS ==========
    -- Selecciona qué display activar y qué dígito mostrar
    process(digit_select, digit0, digit1, digit2, digit3)
    begin
        case digit_select is
            when "00" =>
                an <= "1110";           -- Activar AN0 (display derecho)
                current_digit <= digit0;
            when "01" =>
                an <= "1101";           -- Activar AN1
                current_digit <= digit1;
            when "10" =>
                an <= "1011";           -- Activar AN2
                current_digit <= digit2;
            when "11" =>
                an <= "0111";           -- Activar AN3 (display izquierdo)
                current_digit <= digit3;
            when others =>
                an <= "1111";           -- Todos apagados
                current_digit <= "0000";
        end case;
    end process;
    
    -- ========== DECODIFICACIÓN A 7 SEGMENTOS ==========
    -- Selecciona función de decodificación según modo de display
    process(current_digit, display_mode, digit_select, special_char0, special_char1)
    begin
        case display_mode is
            when "00" => -- Modo hexadecimal normal
                seg <= hex_to_7seg(current_digit);
                
            when "01" => -- Modo SUBE
                case digit_select is
                    when "11" => seg <= char_to_7seg('S');  -- Display 3: S
                    when "10" => seg <= char_to_7seg('U');  -- Display 2: U
                    when "01" => seg <= char_to_7seg('B');  -- Display 1: B
                    when "00" => seg <= char_to_7seg('E');  -- Display 0: E
                    when others => seg <= hex_to_7seg(current_digit);
                end case;
                
            when "10" => -- Modo BAJA
                case digit_select is
                    when "11" => seg <= char_to_7seg('B');  -- Display 3: B
                    when "10" => seg <= char_to_7seg('A');  -- Display 2: A
                    when "01" => seg <= char_to_7seg('J');  -- Display 1: J
                    when "00" => seg <= char_to_7seg('A');  -- Display 0: A
                    when others => seg <= hex_to_7seg(current_digit);
                end case;
                
            when "11" => -- Modo caracteres especiales (OH, FAIL)
                case digit_select is
                    when "01" => seg <= char_to_7seg(special_char1);  -- Display 1
                    when "00" => seg <= char_to_7seg(special_char0);  -- Display 0
                    when others => seg <= char_to_7seg('-');  -- Displays 2,3 apagados
                end case;
                
            when others =>
                seg <= hex_to_7seg(current_digit);
        end case;
    end process;
end Behavioral;
