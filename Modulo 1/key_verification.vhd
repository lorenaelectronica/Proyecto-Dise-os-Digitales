library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Módulo de verificación de clave
entity key_verification is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           verify_key : in STD_LOGIC;
           input_key : in STD_LOGIC_VECTOR(3 downto 0);
           stored_key : in STD_LOGIC_VECTOR(3 downto 0);
           key_correct : out STD_LOGIC;
           key_incorrect : out STD_LOGIC);
end key_verification;

architecture Behavioral of key_verification is
    type state_type is (IDLE, CHECKING);
    signal state : state_type := IDLE;
begin

    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            key_correct <= '0';
            key_incorrect <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    key_correct <= '0';
                    key_incorrect <= '0';
                    if verify_key = '1' then
                        state <= CHECKING;
                    end if;
                    
                when CHECKING =>
                    if input_key = stored_key then
                        key_correct <= '1';
                        key_incorrect <= '0';
                    else
                        key_correct <= '0';
                        key_incorrect <= '1';
                    end if;
                    state <= IDLE;
                    
                when others =>
                    state <= IDLE;
                    key_correct <= '0';
                    key_incorrect <= '0';
            end case;
        end if;
    end process;

end Behavioral;
