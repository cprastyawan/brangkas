`timescale 1ns/1ps

module tb_top;

    // =========================================================================
    // DUT signals
    // =========================================================================
    reg        clk;
    reg  [3:0] sw;
    reg  [3:0] btn;
    wire       led6_r, led6_g, led6_b;

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    top dut (
        .clk   (clk),
        .sw    (sw),
        .btn   (btn),
        .led6_r(led6_r),
        .led6_g(led6_g),
        .led6_b(led6_b)
    );

    // =========================================================================
    // Speed up the sub-modules for simulation only (does not touch the RTL
    // files). Debounce counters and the blink divider are set to realistic
    // 125 MHz timings in the design, which would take milliseconds of
    // simulated time to exercise; here they are scaled down so the whole
    // testbench runs in microseconds while still covering the same logic.
    // =========================================================================
    localparam SIM_DEBOUNCE_MAX = 10;   // was 1_000_000
    localparam SIM_DIV_INPUT_HZ = 1000; // was 125_000_000
    localparam SIM_DIV_DESIRED  = 2;    // toggles every 500 clk cycles

    defparam dut.btn_debouncers[0].u_debounce.COUNTER_MAX = SIM_DEBOUNCE_MAX;
    defparam dut.btn_debouncers[1].u_debounce.COUNTER_MAX = SIM_DEBOUNCE_MAX;
    defparam dut.btn_debouncers[2].u_debounce.COUNTER_MAX = SIM_DEBOUNCE_MAX;
    defparam dut.btn_debouncers[3].u_debounce.COUNTER_MAX = SIM_DEBOUNCE_MAX;
    defparam dut.u_clkdiv.INPUT_FREQUENCY   = SIM_DIV_INPUT_HZ;
    defparam dut.u_clkdiv.DESIRED_FREQUENCY = SIM_DIV_DESIRED;

    // =========================================================================
    // Clock: 10 ns period (100 MHz sim clock, timing scale set by defparams
    // above rather than by matching the real 125 MHz board clock)
    // =========================================================================
    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // Bookkeeping
    // =========================================================================
    integer errors = 0;
    integer checks = 0;

    // Debounce settle time: 2-stage sync + COUNTER_MAX cycles, plus margin
    localparam DB_SETTLE = (SIM_DEBOUNCE_MAX + 4) * CLK_PERIOD;

    function [95:0] state_name;
        input [3:0] state;
        begin
            case (state)
                4'b0000: state_name = "IDLE";
                4'b0001: state_name = "PIN_TRUE";
                4'b0010: state_name = "PIN_FALSE";
                4'b0100: state_name = "LOCKED";
                4'b1000: state_name = "PIN_CHANGE";
                default: state_name = "UNKNOWN";
            endcase
        end
    endfunction

    // =========================================================================
    // Tasks
    // =========================================================================

    // Hold btn[idx] high long enough to clear the debouncer, then bring it
    // back low and let that settle too, so the FSM's btn_pulse edge detector
    // is ready to catch the next press.
    task press_btn(input integer idx);
        begin
            btn[idx] = 1'b1;
            #(DB_SETTLE);
            btn[idx] = 1'b0;
            #(DB_SETTLE);
        end
    endtask

    // BTN2 also drives the raw, non-debounced reset path (rst = btn[2]
    // directly), so it doesn't need to wait for the debouncer to act as a
    // reset - only a couple of clock edges while held high.
    task pulse_reset;
        begin
            btn[2] = 1'b1;
            @(posedge clk);
            @(posedge clk);
            btn[2] = 1'b0;
            #(DB_SETTLE); // let the debounced copy of btn[2] settle too
        end
    endtask

    task check_led(input [511:0] label, input exp_r, input exp_g, input exp_b);
        begin
            checks = checks + 1;
            if ((led6_r !== exp_r) || (led6_g !== exp_g) || (led6_b !== exp_b)) begin
                errors = errors + 1;
                $display("[%0t] FAIL (%0s): expected RGB=%b%b%b, got %b%b%b",
                          $time, label, exp_r, exp_g, exp_b, led6_r, led6_g, led6_b);
            end else begin
                $display("[%0t] PASS (%0s): RGB=%b%b%b as expected",
                          $time, label, led6_r, led6_g, led6_b);
            end
        end
    endtask

    task check_state(input [511:0] label, input [3:0] exp_state);
        begin
            checks = checks + 1;
            if (dut.state !== exp_state) begin
                errors = errors + 1;
                $display("[%0t] FAIL (%0s): expected state=%0s, got %0s",
                          $time, label, state_name(exp_state), state_name(dut.state));
            end else begin
                $display("[%0t] PASS (%0s): state=%0s as expected",
                          $time, label, state_name(dut.state));
            end
        end
    endtask

    // =========================================================================
    // Stimulus
    // =========================================================================
    initial begin
        clk = 0;
        sw  = 4'b0000;
        btn = 4'b0000;

        // Work around debounce.v's missing reset on btn_out (see chat note):
        // give it a known value at t=0 instead of leaving it X forever.
        force dut.btn_debouncers[0].u_debounce.btn_out = 1'b0;
        force dut.btn_debouncers[1].u_debounce.btn_out = 1'b0;
        force dut.btn_debouncers[2].u_debounce.btn_out = 1'b0;
        force dut.btn_debouncers[3].u_debounce.btn_out = 1'b0;
        #1;
        release dut.btn_debouncers[0].u_debounce.btn_out;
        release dut.btn_debouncers[1].u_debounce.btn_out;
        release dut.btn_debouncers[2].u_debounce.btn_out;
        release dut.btn_debouncers[3].u_debounce.btn_out;

        // ---- Power-on reset ----------------------------------------------
        pulse_reset;
        check_state("after reset",      4'b0000);
        check_led  ("IDLE - LED off",   0, 0, 0);

        // ---- Wrong PIN, attempt 1/3 ---------------------------------------
        sw = 4'b1111; // default stored pin is 0000, so this is wrong
        press_btn(0); // BTN0 = enter pin
        check_state("wrong pin #1",      4'b0010);
        check_led  ("PIN_FALSE - red",  1, 0, 0);

        // ---- Wrong PIN, attempt 2/3 ---------------------------------------
        sw = 4'b1010;
        press_btn(0);
        check_state("wrong pin #2",      4'b0010);
        check_led  ("PIN_FALSE - red",  1, 0, 0);

        // ---- Wrong PIN, attempt 3/3 -> should lock -------------------------
        sw = 4'b0101;
        press_btn(0);
        // fail_count reaches 3 on this clock edge; FSM needs one more clock
        // to notice max_reached and move to LOCKED (see chat note on timing)
        @(posedge clk);
        @(posedge clk);
        check_state("3rd wrong pin -> locked", 4'b0100);

        // ---- Check red blinking in LOCKED ----------------------------------
        // clk_div free-runs from the very first system reset, not from the
        // moment LOCKED is entered - so its phase when we get here is
        // whatever it happens to be, not necessarily "just turned on". We
        // therefore check for a TOGGLE (blinking is happening) rather than
        // an absolute ON/OFF value at a fixed offset. Full toggle period
        // (scaled for sim) is 5000 ns, so 5500 ns guarantees we cross at
        // least one edge without also crossing two.
        checks = checks + 1;
        if ((led6_g !== 1'b0) || (led6_b !== 1'b0)) begin
            errors = errors + 1;
            $display("[%0t] FAIL (LOCKED - green/blue must stay off): got G=%b B=%b",
                      $time, led6_g, led6_b);
        end else begin
            $display("[%0t] PASS (LOCKED - green/blue stay off)", $time);
        end

        begin : blink_check
            reg r_phase1, r_phase2, r_phase3;
            r_phase1 = led6_r;
            #(5500);
            r_phase2 = led6_r;
            #(5500);
            r_phase3 = led6_r;

            checks = checks + 1;
            if ((r_phase2 == r_phase1) || (r_phase3 == r_phase2)) begin
                errors = errors + 1;
                $display("[%0t] FAIL (LOCKED - red must blink): samples were %b -> %b -> %b (expected to toggle each time)",
                          $time, r_phase1, r_phase2, r_phase3);
            end else begin
                $display("[%0t] PASS (LOCKED - red blinks): samples were %b -> %b -> %b",
                          $time, r_phase1, r_phase2, r_phase3);
            end
        end

        // ---- Reset clears LOCKED and the fail counter ----------------------
        pulse_reset;
        check_state("after reset from locked", 4'b0000);
        check_led  ("IDLE - LED off",           0, 0, 0);
        if (dut.fail_count !== 2'd0) begin
            errors = errors + 1;
            $display("[%0t] FAIL: fail_count not cleared by reset (got %0d)",
                      $time, dut.fail_count);
        end

        // ---- Correct default PIN (0000) -------------------------------------
        sw = 4'b0000;
        press_btn(0);
        check_state("correct default pin",  4'b0001);
        check_led  ("PIN_TRUE - green",      0, 1, 0);

        // ---- Change PIN: new pin must be on sw when BTN1 is pressed ---------
        sw = 4'b1010; // new pin, captured at the PIN_TRUE -> PIN_CHANGE edge
        press_btn(1); // BTN1 = enter pin change
        check_state("entering pin change",   4'b1000);
        check_led  ("PIN_CHANGE - purple",   1, 0, 1);
        if (dut.stored_pin !== 4'b1010) begin
            errors = errors + 1;
            $display("[%0t] FAIL: stored_pin not updated (got %b)",
                      $time, dut.stored_pin);
        end

        // ---- Lock (BTN3) returns to IDLE from PIN_CHANGE ---------------------
        press_btn(3); // BTN3 = lock
        check_state("lock from pin_change",  4'b0000);
        check_led  ("IDLE - LED off",         0, 0, 0);

        // ---- Old default PIN should now fail ----------------------------------
        sw = 4'b0000;
        press_btn(0);
        check_state("old pin now wrong",      4'b0010);
        check_led  ("PIN_FALSE - red",       1, 0, 0);

        // ---- New PIN should now work (pressing BTN0 again, no hardware
        //      reset - proving the new pin was actually committed) ---------
        sw = 4'b1010;
        press_btn(0);
        check_state("new pin correct",        4'b0001);
        check_led  ("PIN_TRUE - green",        0, 1, 0);

        // ---- Lock from PIN_TRUE back to IDLE ----------------------------------
        press_btn(3);
        check_state("lock from pin_true",      4'b0000);
        check_led  ("IDLE - LED off",           0, 0, 0);

        // ---- Summary -----------------------------------------------------
        #100;
        $display("========================================================");
        $display("TESTBENCH DONE: %0d checks run, %0d failed", checks, errors);
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $display("========================================================");
        $finish;
    end

    // Safety timeout in case something hangs
    initial begin
        #200000;
        $display("[%0t] TIMEOUT: simulation did not finish in time", $time);
        $finish;
    end

endmodule