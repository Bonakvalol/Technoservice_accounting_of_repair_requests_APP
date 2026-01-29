using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows;

namespace RepairRequestsApp
{
    public partial class EmployeesWindow : Window
    {
        private string connectionString;

        public EmployeesWindow(string connectionString)
        {
            InitializeComponent();
            this.connectionString = connectionString;
            LoadEmployees();
        }

        private void LoadEmployees()
        {
            try
            {
                string query = "SELECT LastName, FirstName, Position, Phone, Email FROM Employees WHERE IsActive = 1 ORDER BY LastName";

                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query, connection))
                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable dataTable = new DataTable();
                    adapter.Fill(dataTable);
                    DataGridEmployees.ItemsSource = dataTable.DefaultView;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки сотрудников: {ex.Message}", "Ошибка");
            }
        }
    }
}