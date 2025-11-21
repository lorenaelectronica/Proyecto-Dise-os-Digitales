-- =====================================================
-- SUBMÓDULO 3: DEBOUNCER (ANTI-REBOTE)
-- =====================================================
-- Filtra rebotes mecánicos de botones mediante
-- sincronización y contador de estabilidad
-- =====================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity debouncer is
Generic (
DEBOUNCE_TIME : integer := 1000000 -- Tiempo de estabilidad
);
Port (
clk : in STD_LOGIC; -- Reloj
reset : in STD_LOGIC; -- Reset
button_in : in STD_LOGIC; -- Botón crudo
button_out : out STD_LOGIC -- Botón filtrado
);
end debouncer;


architecture Behavioral of debouncer is
signal btn_sync : STD_LOGIC_VECTOR(2 downto 0) := "000"; -- Sincronización
signal btn_stable : STD_LOGIC := '0'; -- Estado filtrado
signal counter : integer range 0 to DEBOUNCE_TIME := 0; -- Contador de tiempo
begin
process(clk, reset)
begin
if reset = '1' then
btn_sync <= "000"; -- Reiniciar sincronización
btn_stable <= '0'; -- Reiniciar salida estable
counter <= 0; -- Reset contador
elsif rising_edge(clk) then
btn_sync <= btn_sync(1 downto 0) & button_in; -- Cadena anti metaestabilidad
if btn_sync(2) /= btn_stable then
if counter = DEBOUNCE_TIME - 1 then
btn_stable <= btn_sync(2); -- Confirmar cambio estable
counter <= 0;
else
counter <= counter + 1; -- Esperar estabilidad
end if;
else
counter <= 0; -- No hay cambio
end if;
end if;
end process;
button_out <= btn_stable; -- Salida filtrada
end Behavioral;

