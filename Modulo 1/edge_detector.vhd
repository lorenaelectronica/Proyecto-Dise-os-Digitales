library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Detector de flanco ascendente
entity edge_detector is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           signal_in : in STD_LOGIC;
           edge_detected : out STD_LOGIC);
end edge_detector;

architecture Behavioral of edge_detector is
    signal signal_reg : STD_LOGIC_VECTOR(1 downto 0) := "00";
begin

    process(clk, reset)
    begin
        if reset = '1' then
            signal_reg <= "00";
        elsif rising_edge(clk) then
            signal_reg <= signal_reg(0) & signal_in;
        end if;
    end process;
    
    edge_detected <= signal_reg(0) and not signal_reg(1);

end Behavioral;
