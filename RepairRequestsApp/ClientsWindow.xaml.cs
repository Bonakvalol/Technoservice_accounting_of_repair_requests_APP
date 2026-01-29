using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows;

namespace RepairRequestsApp
{
    public partial class ClientsWindow : Window
    {
        private string connectionString;

        public ClientsWindow(string connectionString)
        {
            InitializeComponent();
            this.connectionString = connectionString;
            LoadClients();
        }

        private void LoadClients()
        {
            try
            {
                string query = "SELECT LastName, FirstName, Phone, Email, CompanyName FROM Clients ORDER BY LastName";

                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query, connection))
                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable dataTable = new DataTable();
                    adapter.Fill(dataTable);
                    DataGridClients.ItemsSource = dataTable.DefaultView;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки клиентов: {ex.Message}", "Ошибка");
            }
        }
    }
}