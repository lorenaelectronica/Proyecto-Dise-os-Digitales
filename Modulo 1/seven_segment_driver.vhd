library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Driver para displays de 7 segmentos con multiplexación
entity seven_segment_driver is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           digit0 : in STD_LOGIC_VECTOR(3 downto 0);
           digit1 : in STD_LOGIC_VECTOR(3 downto 0);
           digit2 : in STD_LOGIC_VECTOR(3 downto 0);
           digit3 : in STD_LOGIC_VECTOR(3 downto 0);
           an : out STD_LOGIC_VECTOR(3 downto 0);
           seg : out STD_LOGIC_VECTOR(6 downto 0));
end seven_segment_driver;

architecture Behavioral of seven_segment_driver is
    signal refresh_counter : unsigned(16 downto 0) := (others => '0');
    signal digit_select : STD_LOGIC_VECTOR(1 downto 0);
    signal current_digit : STD_LOGIC_VECTOR(3 downto 0);
    
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
            when "1111" => segments := "0001110"; -- F
            when others => segments := "1111111";
        end case;
        return segments;
    end function;
    
begin

    -- Contador de refresco para multiplexación
    process(clk, reset)
    begin
        if reset = '1' then
            refresh_counter <= (others => '0');
        elsif rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;
    
    digit_select <= std_logic_vector(refresh_counter(16 downto 15));
    
    -- Selección de dígito
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
    
    seg <= hex_to_7seg(current_digit);

end Behavioral;
