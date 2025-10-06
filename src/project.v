`default_nettype none

module tt_um_vga_example(
    input wire [7:0] ui_in,    // Dedizierte Eingänge
    output wire [7:0] uo_out,  // Dedizierte Ausgänge
    input wire [7:0] uio_in,   // IOs: Eingangs-Pfad
    output wire [7:0] uio_out, // IOs: Ausgangs-Pfad
    output wire [7:0] uio_oe,  // IOs: Enable-Pfad (aktiv High: 0=Eingang, 1=Ausgang)
    input wire ena,            // immer 1, solange das Design mit Strom versorgt ist - kann ignoriert werden
    input wire clk,            // Takt
    input wire rst_n           // reset_n - Low = Reset
);

    // VGA-signale
    wire hsync;
    wire vsync;
    wire [1:0] R;
    wire [1:0] G;
    wire [1:0] B;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // VGA-Ausgänge zuordnen, um Farbinformationen anzuzeigen
    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

    // Ungenutzte Ausgänge auf 0 setzen
    assign uio_out = 0;
    assign uio_oe  = 0;

    // Warnungen für ungenutzte Signale unterdrücken
    wire _unused_ok = &{ena, uio_in};

    // Instantiierung des VGA-Signalgenerators
    hvsync_generator hvsync_gen(
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(pix_x),
        .vpos(pix_y)
    );

    // Register zur Speicherung der X-Position des Rechtecks
    reg [9:0] rect_pos_x;

    // Rechteckgröße und Verschiebungsgeschwindigkeit
    localparam [9:0] RECT_WIDTH = 240;
    localparam [9:0] RECT_HEIGHT = 100;
    localparam [9:0] MOVE_SPEED = 1;

    // Bewegen des Rechtecks
    always @(posedge vsync or negedge rst_n) begin
        if (~rst_n) begin
            rect_pos_x <= 200; // Anfangsposition
        end else begin
            if (ui_in[0]) begin
                // Bewegung nach rechts, wenn Pin 0 High ist
                rect_pos_x <= rect_pos_x + MOVE_SPEED;
            end
            if (!ui_in[1]) begin
                // Bewegung nach links, wenn Pin 1 Low ist
                rect_pos_x <= rect_pos_x - MOVE_SPEED;
            end
        end
    end

    // Zeichnen eines roten Rechtecks auf dem Bildschirm, basierend auf aktueller Position
    wire rectangle_active = 
        (pix_x >= rect_pos_x && pix_x < rect_pos_x + RECT_WIDTH) &&
        (pix_y >= 100 && pix_y < 100 + RECT_HEIGHT);
    
    assign R = (video_active && rectangle_active) ? 2'b11 : 2'b00; // Volles rotes Signal
    assign G = 2'b00; // Kein grünes Signal
    assign B = 2'b00; // Kein blaues Signal

endmodule
