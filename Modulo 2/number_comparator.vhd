library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity number_comparator is
    Port (
        clk : in STD_LOGIC;                    -- Reloj maestro
        reset : in STD_LOGIC;                  -- Reset asíncrono
        compare_enable : in STD_LOGIC;         -- Pulso para realizar comparación
        user_number : in unsigned(3 downto 0); -- Número ingresado por usuario
        target_number : in unsigned(3 downto 0); -- Número objetivo
        result_lower : out STD_LOGIC;          -- '1' si user < target (1 ciclo)
        result_higher : out STD_LOGIC;         -- '1' si user > target (1 ciclo)
        result_equal : out STD_LOGIC           -- '1' si user = target (1 ciclo)
    );
end number_comparator;

architecture Behavioral of number_comparator is
begin
    -- Proceso de comparación
    process(clk, reset)
    begin
        if reset = '1' then
            result_lower <= '0';
            result_higher <= '0';
            result_equal <= '0';
        elsif rising_edge(clk) then
            -- Por defecto, todas las señales en '0'
            result_lower <= '0';
            result_higher <= '0';
            result_equal <= '0';
            
            -- Realizar comparación solo cuando está habilitado
            if compare_enable = '1' then
                if user_number < target_number then
                    result_lower <= '1';   -- Usuario debe subir
                elsif user_number > target_number then
                    result_higher <= '1';  -- Usuario debe bajar
                else
                    result_equal <= '1';   -- Usuario acertó
                end if;
            end if;
        end if;
    end process;
end Behavioral;

