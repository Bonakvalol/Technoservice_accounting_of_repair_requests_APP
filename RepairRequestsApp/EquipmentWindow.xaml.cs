using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows;

namespace RepairRequestsApp
{
    public partial class EquipmentWindow : Window
    {
        private string connectionString;

        public EquipmentWindow(string connectionString)
        {
            InitializeComponent();
            this.connectionString = connectionString;
            LoadEquipment();
        }

        private void LoadEquipment()
        {
            try
            {
                string query = @"
                    SELECT 
                        e.SerialNumber,
                        e.Model,
                        et.TypeName,
                        c.LastName + ' ' + c.FirstName AS ClientName,
                        e.Status
                    FROM Equipment e
                    INNER JOIN EquipmentTypes et ON e.EquipmentTypeID = et.EquipmentTypeID
                    INNER JOIN Clients c ON e.ClientID = c.ClientID
                    ORDER BY e.SerialNumber";

                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query, connection))
                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable dataTable = new DataTable();
                    adapter.Fill(dataTable);
                    DataGridEquipment.ItemsSource = dataTable.DefaultView;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки оборудования: {ex.Message}", "Ошибка");
            }
        }
    }
}