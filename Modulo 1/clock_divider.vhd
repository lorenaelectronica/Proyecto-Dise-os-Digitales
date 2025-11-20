library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Clock Divider ÓPTIMO para simulación
-- Genera 1 Hz simulado en tiempo razonable para ver detalles
entity clock_divider is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           clk_1hz : out STD_LOGIC);
end clock_divider;

architecture Behavioral of clock_divider is
    -- CONFIGURACIÓN ÓPTIMA PARA SIMULACIÓN:
    -- MAX_COUNT = 5 es el punto dulce entre velocidad y visibilidad
    -- 1 "segundo" simulado = 100 nanosegundos
    -- 30 segundos de bloqueo = 3 microsegundos
    -- Suficientemente lento para ver transiciones en waveform
    -- Suficientemente rápido para simulación (< 20us total)
    
    constant MAX_COUNT : integer := 5;
    
    
    signal counter : integer range 0 to MAX_COUNT-1 := 0;
    signal clk_1hz_reg : STD_LOGIC := '0';
begin

    process(clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
            clk_1hz_reg <= '0';
        elsif rising_edge(clk) then
            if counter = MAX_COUNT-1 then
                counter <= 0;
                clk_1hz_reg <= not clk_1hz_reg;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    
    clk_1hz <= clk_1hz_reg;

end Behavioral;