using Fisa.Crm.Application.Database;
using Fisa.Crm.Application.WorkItems;
using Serilog;
using Serilog.Events;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("Postgres")
    ?? Environment.GetEnvironmentVariable(NpgsqlConnectionFactory.DefaultEnvironmentVariable)
    ?? string.Empty;

if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException("Missing PostgreSQL connection string. Set FISA_CRM_DB_CONNECTION_STRING or the Postgres connection string in appsettings.");
}
builder.Host.UseSerilog((ctx, lc) => lc
                            .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
                            .WriteTo.File("logs/log.txt", rollingInterval: RollingInterval.Day)
                            .WriteTo.Console());
builder.Services.AddSingleton<IDbConnectionFactory>(_ => new NpgsqlConnectionFactory(connectionString));
builder.Services.AddSingleton<IClock, SystemClock>();
builder.Services.AddSingleton<IWorkflowRuntimeClient, NoopWorkflowRuntimeClient>();
builder.Services.AddSingleton<IWorkItemStateMachine, WorkItemStateMachine>();
builder.Services.AddScoped<IWorkItemAppService, WorkItemAppService>();
builder.Services.AddControllers();

var app = builder.Build();

app.MapControllers();

app.Run();

public sealed class SystemClock : IClock
{
    public DateTimeOffset UtcNow => DateTimeOffset.UtcNow;
}
