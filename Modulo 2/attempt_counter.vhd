-- =====================================================
-- SUBMÓDULO 5: CONTADOR DE INTENTOS
-- =====================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity attempt_counter is
Generic (MAX_ATTEMPTS : integer := 5);
Port (
clk : in STD_LOGIC;
reset : in STD_LOGIC;
reset_attempts : in STD_LOGIC; -- Reinicia intentos
decrement : in STD_LOGIC; -- Resta intento
attempts_left : out integer range 0 to MAX_ATTEMPTS; -- Intentos
max_reached : out STD_LOGIC -- Se quedó sin intentos
);
end attempt_counter;


architecture Behavioral of attempt_counter is
signal counter : integer range 0 to MAX_ATTEMPTS := MAX_ATTEMPTS; -- Valor actual
begin
process(clk, reset)
begin
if reset = '1' then
counter <= MAX_ATTEMPTS; -- Reinicio total
elsif rising_edge(clk) then
if reset_attempts = '1' then
counter <= MAX_ATTEMPTS; -- Reiniciar
elsif decrement = '1' and counter > 0 then
counter <= counter - 1; -- Decrementar
end if;
end if;
end process;
attempts_left <= counter; -- Salida
max_reached <= '1' when counter = 0 else '0'; -- Sin intentos
end Behavioral;

