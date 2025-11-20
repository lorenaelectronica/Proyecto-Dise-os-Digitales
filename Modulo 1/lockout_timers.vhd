library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Temporizador de bloqueo con cuenta regresiva
entity lockout_timer is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           clk_1hz : in STD_LOGIC;
           start_lockout : in STD_LOGIC;
           lockout_active : out STD_LOGIC;
           time_remaining : out STD_LOGIC_VECTOR(5 downto 0));
end lockout_timer;

architecture Behavioral of lockout_timer is
    constant LOCKOUT_TIME : integer := 30; -- 30 segundos
    signal counter : unsigned(5 downto 0) := (others => '0');
    signal locked : STD_LOGIC := '0';
    signal clk_1hz_prev : STD_LOGIC := '0';
begin

    process(clk, reset)
    begin
        if reset = '1' then
            counter <= (others => '0');
            locked <= '0';
            clk_1hz_prev <= '0';
        elsif rising_edge(clk) then
            clk_1hz_prev <= clk_1hz;
            
            if start_lockout = '1' and locked = '0' then
                counter <= to_unsigned(LOCKOUT_TIME, 6);
                locked <= '1';
            elsif locked = '1' then
                -- Detectar flanco ascendente de clk_1hz
                if clk_1hz = '1' and clk_1hz_prev = '0' then
                    if counter > 0 then
                        counter <= counter - 1;
                    else
                        locked <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    lockout_active <= locked;
    time_remaining <= std_logic_vector(counter);

end Behavioral;
