library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reaction_timer is
    Port (
        clk    : in  STD_LOGIC; -- 100MHz clock
        clear  : in  STD_LOGIC;
        start  : in  STD_LOGIC;
        stop   : in  STD_LOGIC;
        led    : out STD_LOGIC; -- LED kích thích
        ja     : out STD_LOGIC_VECTOR (6 downto 0); -- giây
        jb     : out STD_LOGIC_VECTOR (6 downto 0); -- 0.01 giây
        jc     : out STD_LOGIC_VECTOR (6 downto 0)  -- 0.1 giây
    );
end reaction_timer;

architecture Behavioral of reaction_timer is

    type state_type is (IDLE, WAIT_2S, REACT, DONE);
    signal state, next_state : state_type;
    --constant CLK_FREQ          : integer := 100000000;
    constant HUNDREDTH_TICKS   : integer := 1000000;   -- 0.01s = 1,000,000 clk

    signal wait_counter        : integer := 0;
    signal random_delay        : integer := 0;

    signal hundredth_counter   : integer range 0 to HUNDREDTH_TICKS := 0;
    signal count_timer         : integer range 0 to 999 := 0;

    signal seed_counter        : unsigned(27 downto 0) := (others => '0');

begin

    -- Random seed generator (runs continuously)
    process(clk)
    begin
        if rising_edge(clk) then
            seed_counter <= seed_counter + 1;
        end if;
    end process;

    -- FSM transition
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                state <= IDLE;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    -- FSM next state logic
    process(state, start, stop, wait_counter)
    begin
        next_state <= state;

        case state is
            when IDLE =>
                if start = '1' then
                    next_state <= WAIT_2S;
                end if;

            when WAIT_2S =>
                if wait_counter >= random_delay then
                    next_state <= REACT;
                end if;

            when REACT =>
                if stop = '1' then
                    next_state <= DONE;
                end if;

            when DONE =>
                if clear = '1' then
                    next_state <= IDLE;
                end if;
        end case;
    end process;

    -- Counters
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    wait_counter <= 0;
                    random_delay <= 200000000 + to_integer(seed_counter) mod 300000001;
                    count_timer <= 0;
                    hundredth_counter <= 0;

                when WAIT_2S =>
                    if wait_counter < random_delay then
                        wait_counter <= wait_counter + 1;
                    end if;

                when REACT =>
                    if hundredth_counter < HUNDREDTH_TICKS - 1 then
                        hundredth_counter <= hundredth_counter + 1;
                    else
                        hundredth_counter <= 0;
                        if count_timer < 999 then
                            count_timer <= count_timer + 1;
                        end if;
                    end if;

                when DONE =>
                    -- giữ nguyên giá trị count_timer
                    null;
            end case;
        end if;
    end process;

    -- LED output
    led <= '1' when state = REACT else '0';

    -- LED 7 segment decoder
    process(count_timer)
        variable sec, tenth, hundredth : integer;
    begin
        sec       := count_timer / 100;
        tenth     := (count_timer / 10) mod 10;
        hundredth := count_timer mod 10;

        -- ja = giây
        case sec is
            when 0 => ja <= "0111111";
            when 1 => ja <= "0000110";
            when 2 => ja <= "1011011";
            when 3 => ja <= "1001111";
            when 4 => ja <= "1100110";
            when 5 => ja <= "1101101";
            when 6 => ja <= "1111101";
            when 7 => ja <= "0000111";
            when 8 => ja <= "1111111";
            when 9 => ja <= "1101111";
            when others => ja <= "0000000";
        end case;

        -- jc = 0.1s
        case tenth is
            when 0 => jc <= "0111111";
            when 1 => jc <= "0000110";
            when 2 => jc <= "1011011";
            when 3 => jc <= "1001111";
            when 4 => jc <= "1100110";
            when 5 => jc <= "1101101";
            when 6 => jc <= "1111101";
            when 7 => jc <= "0000111";
            when 8 => jc <= "1111111";
            when 9 => jc <= "1101111";
            when others => jc <= "0000000";
        end case;

        -- jb = 0.01s
        case hundredth is
            when 0 => jb <= "0111111";
            when 1 => jb <= "0000110";
            when 2 => jb <= "1011011";
            when 3 => jb <= "1001111";
            when 4 => jb <= "1100110";
            when 5 => jb <= "1101101";
            when 6 => jb <= "1111101";
            when 7 => jb <= "0000111";
            when 8 => jb <= "1111111";
            when 9 => jb <= "1101111";
            when others => jb <= "0000000";
        end case;
    end process;

end Behavioral;
