using System.Data;
using Npgsql;

namespace Fisa.Crm.Application.Database;

public interface IDbConnectionFactory
{
    IDbConnection Create();
}

public sealed class NpgsqlConnectionFactory : IDbConnectionFactory
{
    public const string DefaultEnvironmentVariable = "FISA_CRM_DB_CONNECTION_STRING";

    private readonly string _connectionString;

    public NpgsqlConnectionFactory(string connectionString)
    {
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new ArgumentException("Connection string is required", nameof(connectionString));
        }

        _connectionString = connectionString;
    }

    public IDbConnection Create()
    {
        return new NpgsqlConnection(_connectionString);
    }

    public static NpgsqlConnectionFactory FromEnvironment(string variableName = DefaultEnvironmentVariable)
    {
        var connectionString = Environment.GetEnvironmentVariable(variableName);

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException($"Missing PostgreSQL connection string. Set environment variable '{variableName}' or pass a connection string explicitly.");
        }

        return new NpgsqlConnectionFactory(connectionString);
    }
}
