library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Convertidor de binario a BCD para números de 0 a 30
entity bcd_converter is
    Port ( binary_in : in STD_LOGIC_VECTOR(5 downto 0);
           tens : out STD_LOGIC_VECTOR(3 downto 0);
           ones : out STD_LOGIC_VECTOR(3 downto 0));
end bcd_converter;

architecture Behavioral of bcd_converter is
    signal value : integer range 0 to 63;
begin

    value <= to_integer(unsigned(binary_in));
    
    process(value)
        variable temp : integer;
    begin
        temp := value;
        tens <= std_logic_vector(to_unsigned(temp / 10, 4));
        ones <= std_logic_vector(to_unsigned(temp mod 10, 4));
    end process;

end Behavioral;