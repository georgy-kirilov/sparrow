var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/", () => "Hello World 3!");

app.MapGet("/name", (IConfiguration configuration) => configuration["NAME"]);

app.Run();
