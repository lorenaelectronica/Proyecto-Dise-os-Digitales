-- =====================================================
-- SUBMÓDULO 1: CLOCK DIVIDER (1 HZ)
-- =====================================================
-- Genera una señal de reloj de 1 Hz desde el reloj maestro
-- de 100 MHz mediante división de frecuencia con contador
-- =====================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity clock_divider_1hz is
Generic (
MAX_COUNT : integer := 50000000 -- Para hardware: 50M (medio segundo a 100 MHz)
-- Para simulación: usar 5
);
Port (
clk : in STD_LOGIC; -- Reloj maestro 100 MHz
reset : in STD_LOGIC; -- Reset asíncrono
clk_1hz : out STD_LOGIC -- Salida de 1 Hz
);
end clock_divider_1hz;


architecture Behavioral of clock_divider_1hz is
signal counter : integer range 0 to MAX_COUNT := 0; -- Contador de ciclos
signal clk_out : STD_LOGIC := '0'; -- Señal de salida registrada
begin
-- Proceso de división de frecuencia
process(clk, reset)
begin
if reset = '1' then
counter <= 0; -- Reiniciar contador en reset
clk_out <= '0'; -- Forzar salida inicial
elsif rising_edge(clk) then
if counter = MAX_COUNT - 1 then
counter <= 0; -- Reiniciar contador al llegar al máximo
clk_out <= not clk_out; -- Cambiar estado para crear reloj dividido
else
counter <= counter + 1; -- Incrementar contador
end if;
end if;
end process;
clk_1hz <= clk_out; -- Asignar señal dividida a salida
end Behavioral;
