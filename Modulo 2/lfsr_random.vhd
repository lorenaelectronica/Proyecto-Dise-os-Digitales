-- =====================================================
-- SUBMÓDULO 2: LFSR (GENERADOR PSEUDOALEATORIO)
-- =====================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity lfsr_random is
Port (
clk : in STD_LOGIC; -- Reloj
reset : in STD_LOGIC; -- Reset asíncrono
capture : in STD_LOGIC; -- Señal para capturar número aleatorio
random_number : out unsigned(3 downto 0) -- Número generado
);
end lfsr_random;


architecture Behavioral of lfsr_random is
signal lfsr : unsigned(15 downto 0) := "1010110011100001"; -- Valor inicial LFSR
signal captured_number : unsigned(3 downto 0) := "0000"; -- Último valor capturado
begin
process(clk, reset)
variable feedback : STD_LOGIC; -- Bit de realimentación
begin
if reset = '1' then
lfsr <= "1010110011100001"; -- Reiniciar patrón
captured_number <= "0000"; -- Reiniciar captura
elsif rising_edge(clk) then
-- LFSR siempre avanzando
feedback := lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10); -- Polinomio
lfsr <= lfsr(14 downto 0) & feedback; -- Desplazar e insertar feedback
if capture = '1' then
captured_number <= lfsr(3 downto 0); -- Capturar últimos 4 bits
end if;
end if;
end process;
random_number <= captured_number; -- Salida del número capturado
end Behavioral;