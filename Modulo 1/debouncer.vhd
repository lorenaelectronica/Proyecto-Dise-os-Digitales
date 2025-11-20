library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Módulo anti-rebote para botones
entity debouncer is
    Generic ( DEBOUNCE_TIME : integer := 100000); -- 10ms a 100MHz
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           button_in : in STD_LOGIC;
           button_out : out STD_LOGIC);
end debouncer;

architecture Behavioral of debouncer is
    signal counter : integer range 0 to DEBOUNCE_TIME-1 := 0;
    signal button_sync : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal button_stable : STD_LOGIC := '0';
begin

    process(clk, reset)
    begin
        if reset = '1' then
            button_sync <= "00";
            button_stable <= '0';
            counter <= 0;
        elsif rising_edge(clk) then
            -- Sincronización de entrada
            button_sync <= button_sync(0) & button_in;
            
            -- Contador de debounce
            if button_sync(1) /= button_stable then
                if counter = DEBOUNCE_TIME-1 then
                    button_stable <= button_sync(1);
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            else
                counter <= 0;
            end if;
        end if;
    end process;
    
    button_out <= button_stable;

end Behavioral;
