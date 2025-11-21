library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity countdown_timer is
    Generic (
        MAX_TIME : integer := 15  -- Tiempo máximo en segundos
    );
    Port (
        clk : in STD_LOGIC;                        -- Reloj maestro
        reset : in STD_LOGIC;                      -- Reset asíncrono
        clk_1hz : in STD_LOGIC;                    -- Señal de 1 Hz para decrementar
        start_timer : in STD_LOGIC;                -- Pulso para iniciar temporizador
        time_remaining : out integer range 0 to MAX_TIME;  -- Tiempo restante
        timer_done : out STD_LOGIC                 -- '1' cuando contador llega a 0
    );
end countdown_timer;

architecture Behavioral of countdown_timer is
    signal counter : integer range 0 to MAX_TIME := 0;  -- Contador regresivo
    signal clk_1hz_prev : STD_LOGIC := '0';  -- Estado previo de clk_1hz (detección de flancos)
    signal active : STD_LOGIC := '0';        -- Indica si el temporizador está activo
begin
    -- Proceso del temporizador
    process(clk, reset)
        variable clk_1hz_edge : STD_LOGIC;  -- Pulso de flanco ascendente de clk_1hz
    begin
        if reset = '1' then
            counter <= 0;
            clk_1hz_prev <= '0';
            active <= '0';
        elsif rising_edge(clk) then
            -- Detectar flanco ascendente de clk_1hz
            clk_1hz_edge := clk_1hz and not clk_1hz_prev;
            clk_1hz_prev <= clk_1hz;
            
            if start_timer = '1' then
                -- Iniciar temporizador con MAX_TIME
                counter <= MAX_TIME;
                active <= '1';
            elsif active = '1' and clk_1hz_edge = '1' then
                -- Decrementar cada segundo (flanco de clk_1hz)
                if counter > 0 then
                    counter <= counter - 1;
                else
                    active <= '0';  -- Detener cuando llega a 0
                end if;
            end if;
        end if;
    end process;
    
    time_remaining <= counter;  -- Salida de tiempo restante
    -- Señal que indica que el temporizador terminó
    timer_done <= '1' when (counter = 0 and active = '0') else '0';
end Behavioral;
