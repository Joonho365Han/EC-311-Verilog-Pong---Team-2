`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:39:45 12/04/2015 
// Design Name: 
// Module Name:    pong 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module pong(rst, clk, R, G, B, HS, VS, R_control, G_control, B_control, quadA, quadB, ca, cb, cc, cd, ce, cf, cg, AN);
    input rst;  // global reset
    input clk;  // 100MHz clk
	 input quadA, quadB;
    
    // color inputs for a given pixel
    input [2:0] R_control, G_control;
    input [1:0] B_control; 
    
    // color outputs to show on display (current pixel)
    output reg [2:0] R, G;
    output reg [1:0] B;
    
    // Synchronization signals
    output HS;
    output VS;
	 
	 
    // Begin clock division
    parameter N = 2;    // parameter for clock division
    reg clk_25Mhz;
    reg [N-1:0] count;
    always @ (posedge clk) begin
        count <= count + 1'b1;
        clk_25Mhz <= count[N-1];
    end
    // End clock division
    /////////////////////////////////////////////////////
    
    // controls:
    wire [10:0] hcount, vcount; // coordinates for the current pixel
    wire blank; // signal to indicate the current coordinate is blank
    //wire figure;    // the figure you want to display!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //wire 
    /////////////////////////////////////////////////////

	 //////////PADDLE CONTROL . 
reg [8:0] PaddlePosition;
reg [17:0] clockcounter;
reg clockREG;

always @ (posedge clk) begin
	clockcounter = clockcounter + 1;
	if (clockcounter == 0) clockREG = ~clockREG;
end

always @ (posedge clockREG)
	if(quadA ^ quadB) begin
		
		if (quadB) PaddlePosition <= PaddlePosition + 1;
		if (quadA) PaddlePosition <= PaddlePosition - 1;
	
		if(&PaddlePosition) begin       // make sure the value doesn't overflow
			PaddlePosition <= PaddlePosition - 1;
		end
		else
		if(~|PaddlePosition) begin       // make sure the value doesn't underflow
			PaddlePosition <= PaddlePosition + 1;
		end
	end

/////////////////////////////////////////////////////////////////
	 
	 
    
    // Call driver
    vga_controller_640_60 vc(
        .rst(rst), 
        .pixel_clk(clk_25Mhz), 
        .HS(HS), 
        .VS(VS), 
        .hcounter(hcount), 
        .vcounter(vcount), 
        .blank(blank));
		  


	//BALL
	reg[9:0] ballX;
	reg [8:0] ballY;
	reg ball_inX, ball_inY;
	
	always@(posedge clk)
	if(ball_inX==0) ball_inX <= (hcount==ballX) & ball_inY; else ball_inX <= !(hcount==ballX+16);
	
	always@(posedge clk)
	if(ball_inY==0) ball_inY <= (vcount==ballY); else ball_inY <= !(vcount==ballY+16);
	
	wire ball = ball_inX & ball_inY;
	

//COLLISION ENGINE
wire border = (hcount[9:3]==0) || (hcount[9:3]==79) || (vcount[8:3]==0) || (vcount[8:3]==59);
wire paddle = (hcount>=PaddlePosition+8) && (hcount<=PaddlePosition+120) && (vcount[8:4]==27);
wire BouncingObject = border | paddle; // active if the border or paddle is redrawing itself

reg ResetCollision;
always @(posedge clk) ResetCollision <= (vcount==500) & (hcount==0);  // active only once for every video frame

reg CollisionX1, CollisionX2, CollisionY1, CollisionY2;
reg [7:0] points;
output ca, cb, cc, cd, ce, cf, cg; // The LED registers.
output [3:0] AN;

	displayleds POINT_DISPLAY ( .inputled(points), .clk(clk), .AN(AN), .ca(ca), .cb(cb), .cc(cc), .cd(cd), .ce(ce), .cf(cf), .cg(cg));

always @(posedge clk) begin
	if(ResetCollision) CollisionX1<=0; 
	else if(BouncingObject & (hcount==ballX   ) & (vcount==ballY+ 8)) CollisionX1<=1;
end

always @(posedge clk) begin
	if(ResetCollision) CollisionX2<=0; 
	else if(BouncingObject & (hcount==ballX+16) & (vcount==ballY+ 8)) CollisionX2<=1;
end

always @(posedge clk) begin
	if(ResetCollision) CollisionY1<=0; 
	else if(BouncingObject & (hcount==ballX+ 8) & (vcount==ballY   )) CollisionY1<=1;
end

always @(posedge clk) begin
	if(ResetCollision) CollisionY2<=0; 
	else if(BouncingObject & (hcount==ballX+ 8) & (vcount==ballY+16)) begin
		CollisionY2<=1;
		if (paddle) points <= points + 1; else points <= 8'b00000000;
	end
end

/////////////////////////////////////////////////////////////////.

//MORE COLLISION

wire UpdateBallPosition = ResetCollision; 

reg ball_dirX, ball_dirY;
always @(posedge clk)
if(UpdateBallPosition)
begin
	if(~(CollisionX1 & CollisionX2))   
	begin
		ballX <= ballX + (ball_dirX ? -1 : 1);
		if(CollisionX2) ball_dirX <= 1; else if(CollisionX1) ball_dirX <= 0;
	end

	if(~(CollisionY1 & CollisionY2)) 
	begin
		ballY <= ballY + (ball_dirY ? -1 : 1);
		if(CollisionY2) ball_dirY <= 1; else if(CollisionY1) ball_dirY <= 0;
	end
end 

/////////////////////////////////////////////////////////////////

wire Rbounce = BouncingObject | ball | (hcount[3] ^ vcount[3]);
wire Gbounce = BouncingObject | ball;
wire Bbounce = BouncingObject | ball;

// send colors:

	//always @ (posedge clk) 
	always @ (posedge clk) 
		begin	// if you are within the valid region
			R = Rbounce;
			G= Gbounce;
			B= Bbounce;
		end
	

endmodule
