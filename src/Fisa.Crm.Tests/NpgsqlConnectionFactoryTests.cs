using Fisa.Crm.Application.Database;
using Npgsql;
using Xunit;

namespace Fisa.Crm.Tests;

public class NpgsqlConnectionFactoryTests
{
    [Fact]
    public void FromEnvironment_throws_when_variable_missing()
    {
        var variable = "FISA_CRM_DB_CONNECTION_STRING_TEST";
        Environment.SetEnvironmentVariable(variable, null);

        var ex = Assert.Throws<InvalidOperationException>(() => NpgsqlConnectionFactory.FromEnvironment(variable));
        Assert.Contains(variable, ex.Message);
    }

    [Fact]
    public void FromEnvironment_creates_factory_when_variable_present()
    {
        var variable = "FISA_CRM_DB_CONNECTION_STRING_TEST";
        var connectionString = "Host=localhost;Username=postgres;Password=pass;Database=fisa_crm";
        Environment.SetEnvironmentVariable(variable, connectionString);

        var factory = NpgsqlConnectionFactory.FromEnvironment(variable);
        using var connection = factory.Create();

        Assert.IsType<NpgsqlConnection>(connection);
        Assert.Equal(connectionString, connection.ConnectionString);

        Environment.SetEnvironmentVariable(variable, null);
    }
}
