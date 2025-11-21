-- =====================================================
-- SUBMÓDULO 4: EDGE DETECTOR
-- =====================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity edge_detector is
Port (
clk : in STD_LOGIC;
reset : in STD_LOGIC;
signal_in : in STD_LOGIC; -- Señal a detectar flanco
edge_detected : out STD_LOGIC -- Pulso 1 ciclo
);
end edge_detector;


architecture Behavioral of edge_detector is
signal signal_prev : STD_LOGIC := '0'; -- Estado previo
begin
process(clk, reset)
begin
if reset = '1' then
signal_prev <= '0'; -- Reiniciar
edge_detected <= '0'; -- Sin pulso
elsif rising_edge(clk) then
edge_detected <= signal_in and not signal_prev; -- Detectar 0?1
signal_prev <= signal_in; -- Guardar último valor
end if;
end process;
end Behavioral;
