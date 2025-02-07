module somegame;
import std::io;
import libc;

// External Raylib function declarations
extern fn void init_window(CInt width, CInt height, char* title)
    @extern("InitWindow");
extern fn void close_window() @extern("CloseWindow");
extern fn bool window_should_close() @extern("WindowShouldClose");
extern fn void begin_drawing() @extern("BeginDrawing");
extern fn void end_drawing() @extern("EndDrawing");
extern fn float get_frame_time() @extern("GetFrameTime");
extern fn void clear_background(Color color)
    @extern("ClearBackground");
extern fn void draw_rectangle(CInt posX, CInt posY, CInt width,
                            CInt height, Color color)
    @extern("DrawRectangle");
extern fn bool is_key_down(CInt key) @extern("IsKeyDown");
extern fn void draw_circle_v(Vector2 position, float radius, Color color)
    @extern("DrawCircleV");
extern fn void set_target_fps(CInt fps) @extern("SetTargetFPS");
extern fn void draw_text(char* text, CInt posX, CInt posY, CInt fontSize,
                        Color color) @extern("DrawText");

// Game states
enum GameState {
    MENU,
    PLAYING,
    GAME_OVER
}

// Difficulty levels
enum Difficulty {
    EASY,
    MEDIUM,
    HARD
}

// Structure representing a paddle (bar)
struct Bar {
    float x;
    float y;
    float width;
    float height;
}

// Definition of the Color structure matching Raylib's version
struct Color @extern("Color") {
    char r;
    char g;
    char b;
    char a;
}

// Definition of Raylib's Vector2 structure
struct Vector2 @extern("Vector2") {
    float x;
    float y;
}

// AI settings for different difficulties
struct AiSettings {
    float speed;
    float reaction_time;
    float prediction_accuracy;
}

// Game settings based on difficulty
struct GameSettings {
    float ball_speed_multiplier;
    float speed_increase_rate;
    AiSettings ai;
}

float screenWidth = 800.0;
float screenHeight = 600.0;

// Key definitions
const KEY_W = 87;
const KEY_S = 83;
const KEY_R = 82;
const KEY_E = 69;  // 'E' key for Easy
const KEY_M = 77;  // 'M' key for Medium
const KEY_H = 72;  // 'H' key for Hard

fn GameSettings get_difficulty_settings(Difficulty diff) {
    switch (diff) {
        case EASY:
            return GameSettings{
                1.0,    // ball_speed_multiplier
                0.005,  // speed_increase_rate
                AiSettings{
                    150.0,  // speed
                    0.5,    // reaction_time
                    0.7     // prediction_accuracy
                }
            };
        case MEDIUM:
            return GameSettings{
                1.2,    // ball_speed_multiplier
                0.01,   // speed_increase_rate
                AiSettings{
                    300.0,  // speed (increased)
                    0.3,    // reaction_time
                    0.85    // prediction_accuracy
                }
            };
        case HARD:
            return GameSettings{
                1.5,    // ball_speed_multiplier
                0.015,  // speed_increase_rate
                AiSettings{
                    400.0,  // speed (significantly increased)
                    0.05,   // reaction_time (decreased)
                    0.98    // prediction_accuracy (increased)
                }
            };
    }
}

fn float predict_ball_y_position(Vector2 ballPos, Vector2 ballSpeed, float rightPaddleX) {
    float time_to_reach = (rightPaddleX - ballPos.x) / ballSpeed.x;
    float predicted_y = ballPos.y + (ballSpeed.y * time_to_reach);
    
    // Handle potential bounces
    while (predicted_y < 0 || predicted_y > screenHeight) {
        if (predicted_y < 0) {
            predicted_y = -predicted_y;  // Bounce off top
        } else if (predicted_y > screenHeight) {
            predicted_y = screenHeight - (predicted_y - screenHeight);  // Bounce off bottom
        }
    }
    
    return predicted_y;
}

// Function to reset game state
fn void reset_game(GameSettings* settings, Vector2* ballPos, Vector2* ballSpeed) {
    ballPos.x = screenWidth / 2.0;
    ballPos.y = screenHeight / 2.0;
    ballSpeed.x = 200.0 * settings.ball_speed_multiplier;
    ballSpeed.y = 150.0 * settings.ball_speed_multiplier;
}

fn int main(String[] args) {
    GameState currentState = GameState.MENU;
    Difficulty currentDifficulty = Difficulty.MEDIUM;
    GameSettings settings = get_difficulty_settings(currentDifficulty);
    
    // Initialize game variables
    Vector2 ballPos = {screenWidth / 2.0, screenHeight / 2.0};
    Vector2 ballSpeed = {200.0 * settings.ball_speed_multiplier,
                        150.0 * settings.ball_speed_multiplier};
    float ball_radius = 10.0;
    
    Bar leftBar = {20.0, screenHeight / 2.0 - 50.0, 10.0, 100.0};
    Bar rightBar = {screenWidth - 30.0, screenHeight / 2.0 - 50.0, 10.0, 100.0};
    
    float timer = 0.0;
    float ai_timer = 0.0;
    float predicted_y = screenHeight / 2.0;

        init_window((CInt)screenWidth, (CInt)screenHeight, "Pong Game");
    set_target_fps(60);
    
    while (!window_should_close()) {
        float dTime = get_frame_time();
        
        switch (currentState) {
            case MENU:
                // Handle menu input
                if (is_key_down(KEY_E)) {
                    currentDifficulty = Difficulty.EASY;
                    settings = get_difficulty_settings(currentDifficulty);
                    reset_game(&settings, &ballPos, &ballSpeed);
                    currentState = GameState.PLAYING;
                }
                if (is_key_down(KEY_M)) {
                    currentDifficulty = Difficulty.MEDIUM;
                    settings = get_difficulty_settings(currentDifficulty);
                    reset_game(&settings, &ballPos, &ballSpeed);
                    currentState = GameState.PLAYING;
                }
                if (is_key_down(KEY_H)) {
                    currentDifficulty = Difficulty.HARD;
                    settings = get_difficulty_settings(currentDifficulty);
                    reset_game(&settings, &ballPos, &ballSpeed);
                    currentState = GameState.PLAYING;
                }
                
                begin_drawing();
                    clear_background(Color{240, 240, 240, 255});
                    char[64] menuText;
                    libc::sprintf(&menuText[0], "PONG GAME");
                    draw_text(&menuText[0], (CInt)(screenWidth/2 - 100), 100, 40,
                             Color{0, 0, 0, 255});
                    
                    libc::sprintf(&menuText[0], "Press E for Easy");
                    draw_text(&menuText[0], (CInt)(screenWidth/2 - 100), 200, 20,
                             Color{0, 0, 0, 255});
                    
                    libc::sprintf(&menuText[0], "Press M for Medium");
                    draw_text(&menuText[0], (CInt)(screenWidth/2 - 100), 250, 20,
                             Color{0, 0, 0, 255});
                    
                    libc::sprintf(&menuText[0], "Press H for Hard");
                    draw_text(&menuText[0], (CInt)(screenWidth/2 - 100), 300, 20,
                             Color{0, 0, 0, 255});
                end_drawing();
                break;
                
            case PLAYING:
                timer += dTime;
                ai_timer += dTime;
                
                // Update ball position
                ballPos.x += ballSpeed.x * dTime;
                ballPos.y += ballSpeed.y * dTime;
                
                // Bounce off top and bottom
                if (ballPos.y - ball_radius <= 0 ||
                    ballPos.y + ball_radius >= screenHeight) {
                    ballSpeed.y = -ballSpeed.y;
                }
                
                // Collision detection with left paddle
                if (ballSpeed.x < 0) {
                    if (ballPos.x - ball_radius <= leftBar.x + leftBar.width) {
                        if (ballPos.y >= leftBar.y &&
                            ballPos.y <= leftBar.y + leftBar.height) {
                            ballSpeed.x = -ballSpeed.x;
                            ballPos.x = leftBar.x + leftBar.width + ball_radius;
                        }
                    }
                }
                
                // Collision detection with right paddle
                if (ballSpeed.x > 0) {
                    if (ballPos.x + ball_radius >= rightBar.x) {
                        if (ballPos.y >= rightBar.y &&
                            ballPos.y <= rightBar.y + rightBar.height) {
                            ballSpeed.x = -ballSpeed.x;
                            ballPos.x = rightBar.x - ball_radius;
                        }
                    }
                }
                
                // AI prediction and movement
                if (ballSpeed.x > 0 && ai_timer >= settings.ai.reaction_time) {
                    predicted_y = predict_ball_y_position(ballPos, ballSpeed, rightBar.x);
                    
                    // Add intentional error based on difficulty
                    if (currentDifficulty != Difficulty.HARD) {
                        predicted_y += (1.0 - settings.ai.prediction_accuracy) *
                                     ((float)(libc::rand() % 100) - 50.0);
                    }
                    ai_timer = 0;
                }
                
                // Move AI paddle with improved positioning
                float rightBarCenter = rightBar.y + rightBar.height / 2.0;
                float target_y = predicted_y - (rightBar.height / 2.0); // Aim to center paddle on predicted position
                
                // Add small deadzone to prevent jitter
                if (libc::labs((CLong)rightBarCenter - (CLong)predicted_y) > 2.0) {
                    if (rightBarCenter < predicted_y) {
                        rightBar.y += settings.ai.speed * dTime;
                    } else if (rightBarCenter > predicted_y) {
                        rightBar.y -= settings.ai.speed * dTime;
                    }
                }
                
                // Ensure paddle stays within screen bounds
                if (rightBar.y < 0) { rightBar.y = 0; }
                if (rightBar.y + rightBar.height > screenHeight) {
                    rightBar.y = screenHeight - rightBar.height;
                }
                
                // Player paddle control
                if (is_key_down(KEY_W)) {
                    leftBar.y -= 250.0 * dTime;
                }
                if (is_key_down(KEY_S)) {
                    leftBar.y += 250.0 * dTime;
                }
                
                // Keep paddles within screen bounds
                if (leftBar.y < 0) { leftBar.y = 0; }
                if (leftBar.y + leftBar.height > screenHeight) {
                    leftBar.y = screenHeight - leftBar.height;
                }
                if (rightBar.y < 0) { rightBar.y = 0; }
                if (rightBar.y + rightBar.height > screenHeight) {
                    rightBar.y = screenHeight - rightBar.height;
                }
                
                // Check for game over
                if ((ballPos.x + ball_radius < 0) ||
                    (ballPos.x - ball_radius > screenWidth)) {
                    currentState = GameState.GAME_OVER;
                }
                
                // Gradual speed increase after 10 seconds
                if (timer > 10.0) {
                    ballSpeed.x *= (1.0 + (double)(settings.speed_increase_rate * dTime));
                    ballSpeed.y *= (1.0 + (double)(settings.speed_increase_rate * dTime));
                }
                
                begin_drawing();
                    clear_background(Color{240, 240, 240, 255});
                    
                    draw_circle_v(ballPos, ball_radius, Color{120, 120, 120, 255});
                    
                    draw_rectangle((CInt)leftBar.x, (CInt)leftBar.y,
                                 (CInt)leftBar.width, (CInt)leftBar.height,
                                 Color{0, 128, 0, 255});
                    
                    draw_rectangle((CInt)rightBar.x, (CInt)rightBar.y,
                                 (CInt)rightBar.width, (CInt)rightBar.height,
                                 Color{0, 128, 0, 255});
                    
                    char[64] timerText;
                    libc::sprintf(&timerText[0], "Time: %.2f", timer);
                    draw_text(&timerText[0], 10, 10, 20, Color{0, 0, 0, 255});
                    
                    char[64] diffText;
                    libc::sprintf(&diffText[0], "Difficulty: %s",
                                 currentDifficulty == Difficulty.EASY ? "Easy" :
                                 currentDifficulty == Difficulty.MEDIUM ? "Medium" :
                                 "Hard");
                    draw_text(&diffText[0], 10, 40, 20, Color{0, 0, 0, 255});
                end_drawing();
                break;
                
            case GAME_OVER:
                if (is_key_down(KEY_R)) {
                    currentState = GameState.MENU;
                    timer = 0.0;
                    reset_game(&settings, &ballPos, &ballSpeed);
                }
                
                begin_drawing();
                    clear_background(Color{240, 240, 240, 255});
                    char[64] gameOverText;
                    libc::sprintf(&gameOverText[0], "Game Over! Time: %.2f",
                                 timer);
                    draw_text(&gameOverText[0], (CInt)(screenWidth/2 - 100), 200,
                             20, Color{0, 0, 0, 255});
                    
                    libc::sprintf(&gameOverText[0], "Press R to Restart");
                    draw_text(&gameOverText[0], (CInt)(screenWidth/2 - 100), 250,
                             20, Color{0, 0, 0, 255});
                end_drawing();
                break;
        }
    }
    
    close_window();
    return 0;
}

