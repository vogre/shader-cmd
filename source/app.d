import std.stdio;
import std.string;
import std.conv;
import std.path;
import std.file;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl3;
import derelict.freeimage.freeimage;
import derelict.freetype.ft;
import image;

SDL_Window *win;
SDL_GLContext context;
int w = 640, h = 480;
int flags = SDL_WINDOW_OPENGL | SDL_WINDOW_BORDERLESS | SDL_WINDOW_SHOWN;
bool running = true;
uint shader = 0, vao = 0, tid = 0, colLoc = 0;

private {
    import std.traits : ReturnType;

    debug {
        import std.stdio : stderr;
        import std.array : join;
        import std.range : repeat;
        import std.string : format;
    }
}

debug {
    static this() {
        _error_callback = function void(GLenum error_code, string function_name, string args) {
            stderr.writefln(`OpenGL function "%s(%s)" failed: "%s."`,
                             function_name, args, gl_error_string(error_code));
        };
    }

    private void function(GLenum, string, string) _error_callback;

    ///
    void set_error_callback(void function(GLenum, string, string) cb) {
        _error_callback = cb;
    }
} else {
    ///
    void set_error_callback(void function(GLenum, string, string) cb) {}
}

/// checkgl checks in a debug build after every opengl call glGetError
/// and calls an error-callback which can be set with set_error_callback
/// a default is provided
ReturnType!func checkgl(alias func, Args...)(Args args) {
    debug scope(success) {
        GLenum error_code = glGetError();

        if(error_code != GL_NO_ERROR) {
            _error_callback(error_code, func.stringof, format("%s".repeat(Args.length).join(", "), args));
        }
    }

    debug if(func is null) {
        throw new Error("%s is null! OpenGL loaded? Required OpenGL version not supported?".format(func.stringof));
    }

    return func(args);
}

/// Converts an OpenGL errorenum to a string
string gl_error_string(GLenum error) {
    final switch(error) {
        case GL_NO_ERROR: return "no error";
        case GL_INVALID_ENUM: return "invalid enum";
        case GL_INVALID_VALUE: return "invalid value";
        case GL_INVALID_OPERATION: return "invalid operation";
        //case GL_STACK_OVERFLOW: return "stack overflow";
        //case GL_STACK_UNDERFLOW: return "stack underflow";
        case GL_INVALID_FRAMEBUFFER_OPERATION: return "invalid framebuffer operation";
        case GL_OUT_OF_MEMORY: return "out of memory";
    }
    assert(false, "invalid enum");
}


bool initSDL_GL(){
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        writefln("Error initializing SDL");
        return false;
    }
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

    win = SDL_CreateWindow("shader-cmd", SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED, w, h, flags);
    if(!win){
        writefln("Error creating SDL window");
        SDL_Quit();
        return false;
    }

    context = SDL_GL_CreateContext(win);
    SDL_GL_SetSwapInterval(1);
    DerelictGL3.reload();
    checkgl!(glClearColor)(0.0, 0.0, 0.0, 1.0);
    glViewport(0, 0, w, h);
    return true;
}

bool initUniforms(){
    colLoc = glGetUniformLocation(shader, "colMap");
    if(colLoc == -1){
        writeln("Error: main shader did not assign id "~
                "to sampler2D colMap");
        return false;
    }

    glUseProgram(shader);
    glUniform1i(colLoc, 0);
    glUseProgram(0);

    return true;
}

bool initTex(){
    assert(exists("1.jpg"));
    SDL_Surface *s = IMG_Load("1.jpg");
    assert(s);

    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    glGenTextures(1, &tid);
    assert(tid > 0);
    glBindTexture(GL_TEXTURE_2D, tid);

    int mode = GL_RGB;
    if(s.format.BytesPerPixel == 4) mode = GL_RGBA;

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, 
            GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    glTexImage2D(GL_TEXTURE_2D, 0, mode, s.w, s.h, 0, mode, 
            GL_UNSIGNED_BYTE, s.pixels);

    SDL_FreeSurface(s);
    return true;
}

bool initVAO(){
    uint vbov, vboc;
    const float[] v = [-0.75f, -0.75f, 0.0f,
          0.75f, 0.75f, 0.0f,
          -0.75f, 0.75f, 0.0f,
          -0.75f, -0.75f, 0.0f,
          0.75f, -0.75f, 0.0f,
          0.75f, 0.75f, 0.0f, ];
    const float[] c = [0.0f, 1.0f,
          1.0f, 0.0f,
          0.0f, 0.0f,
          0.0f, 1.0f,
          1.0f, 1.0f,
          1.0f, 0.0f, ];
    glGenVertexArrays(1, &vao);
    assert(vao > 0);

    glBindVertexArray(vao);

    glGenBuffers(1, &vbov);
    assert(vbov > 0);
    glBindBuffer(GL_ARRAY_BUFFER, vbov);
    glBufferData(GL_ARRAY_BUFFER, v.length * GL_FLOAT.sizeof, v.ptr, 
            GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glGenBuffers(1, &vboc);
    assert(vboc > 0);
    glBindBuffer(GL_ARRAY_BUFFER, vboc);
    glBufferData(GL_ARRAY_BUFFER, c.length * GL_FLOAT.sizeof, c.ptr,
            GL_STATIC_DRAW);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, null);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glBindVertexArray(0);

    return true;
}

bool initShaders(){
    const string vshader = "
#version 330
    layout(location = 0) in vec3 pos;
    layout(location = 1) in vec2 texCoords;

    out vec2 coords;

    void main(void)
    {
        coords = texCoords.st;

        gl_Position = vec4(pos, 1.0);
    }
    ";
    const string fshader = "
#version 330

        uniform sampler2D colMap;

    in vec2 coords;

    void main(void)
    {
        vec3 col = texture2D(colMap, coords.st).xyz;

        gl_FragColor = vec4(col, 1.0);
    }
    ";

    shader = glCreateProgram();
    if(shader == 0){
        writeln("Error: GL did not assigh main shader program id");
        return false;
    }
    int vshad = glCreateShader(GL_VERTEX_SHADER);
    const char *vptr = toStringz(vshader);
    glShaderSource(vshad, 1, &vptr, null);
    glCompileShader(vshad);
    int status, len;
    glGetShaderiv(vshad, GL_COMPILE_STATUS, &status);
    if(status == GL_FALSE){
        glGetShaderiv(vshad, GL_INFO_LOG_LENGTH, &len);
        char[] error = new char[len];
        glGetShaderInfoLog(vshad, len, null, cast(char*)error);
        writeln(error);
        return false;
    }
    int fshad = glCreateShader(GL_FRAGMENT_SHADER);
    const char *fptr = toStringz(fshader);
    glShaderSource(fshad, 1, &fptr, null);
    glCompileShader(fshad);
    glGetShaderiv(vshad, GL_COMPILE_STATUS, &status);
    if(status == GL_FALSE){
        glGetShaderiv(fshad, GL_INFO_LOG_LENGTH, &len);
        char[] error = new char[len];
        glGetShaderInfoLog(fshad, len, null, cast(char*)error);
        writeln(error);
        return false;
    }
    glAttachShader(shader, vshad);
    glAttachShader(shader, fshad);
    glLinkProgram(shader);
    glGetShaderiv(shader, GL_LINK_STATUS, &status);
    if(status == GL_FALSE){
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);
        char[] error = new char[len];
        glGetShaderInfoLog(shader, len, null, cast(char*)error);
        writeln(error);
        return false;
    }
    return true;
}

void try_load_new_shader(string file_name)
{

}

bool do_things()
{
    try{
        DerelictSDL2.load();
    }catch(Exception e){
        writeln("Error loading SDL2 lib");
        return false;
    }
    try{
        DerelictGL3.load();
    }catch(Exception e){
        writeln("Error loading GL3 lib");
        return false;
    }
    try{
        DerelictSDL2Image.load();
    }catch(Exception e){
        writeln("Error loading SDL image lib ", e);
        return false;
    }

    writeln("Init SDL_GL: ", initSDL_GL());
    writeln("Init shaders: ", initShaders());
    writeln("Init VAO: ", initVAO());
    writeln("Init uniforms: ", initUniforms());
    writeln("Init textures: ", initTex());

    while(running){
        SDL_Event e;
        while(SDL_PollEvent(&e)){
            switch(e.type){
                case SDL_KEYDOWN:
                    if (e.key.keysym.sym == SDLK_ESCAPE)
                        running = false;
                    break;
                default:
                    break;
            }
        }
        glClear(GL_COLOR_BUFFER_BIT);

        glUseProgram(shader);

        glBindVertexArray(vao);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, tid);

        glDrawArrays(GL_TRIANGLES, 0, 6);

        glBindTexture(GL_TEXTURE_2D, 0);
        glBindVertexArray(0);
        glUseProgram(0);

        SDL_GL_SwapWindow(win);
    }

    SDL_GL_DeleteContext(context);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}

void init()
{
    // Load the FreeImage library.
    DerelictFI.load();
    // Load the FreeType library.
    DerelictFT.load();
}

void uninit()
{

}

int main(string[] args)
{
    init();
    load_image("./1.jpg");
    do_things();
    return 0;
}
