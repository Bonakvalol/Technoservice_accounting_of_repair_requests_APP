using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows;

namespace RepairRequestsApp
{
    public partial class PartsWindow : Window
    {
        private string connectionString;

        public PartsWindow(string connectionString)
        {
            InitializeComponent();
            this.connectionString = connectionString;
            LoadParts();
        }

        private void LoadParts()
        {
            try
            {
                string query = "SELECT PartNumber, PartName, Category, UnitPrice, QuantityInStock FROM SpareParts WHERE IsActive = 1 ORDER BY PartName";

                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query, connection))
                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable dataTable = new DataTable();
                    adapter.Fill(dataTable);
                    DataGridParts.ItemsSource = dataTable.DefaultView;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки запчастей: {ex.Message}", "Ошибка");
            }
        }
    }
}