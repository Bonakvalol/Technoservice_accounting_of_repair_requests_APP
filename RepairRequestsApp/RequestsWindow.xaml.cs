using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows;
using System.Windows.Controls;

namespace RepairRequestsApp
{
    public partial class RequestsWindow : Window
    {
        private string connectionString;

        public RequestsWindow(string connectionString)
        {
            InitializeComponent();
            this.connectionString = connectionString;
            LoadData();
        }

        private void LoadData()
        {
            try
            {
                string statusFilter = "";
                if (CbStatus.SelectedIndex > 0)
                {
                    ComboBoxItem item = (ComboBoxItem)CbStatus.SelectedItem;
                    statusFilter = $" AND r.Status = '{item.Content}'";
                }

                string query = $@"
                    SELECT 
                        r.RequestNumber,
                        r.RequestDate,
                        c.LastName + ' ' + c.FirstName AS ClientName,
                        e.Model AS EquipmentName,
                        r.ProblemDescription,
                        r.Priority,
                        r.Status
                    FROM RepairRequests r
                    INNER JOIN Clients c ON r.ClientID = c.ClientID
                    INNER JOIN Equipment e ON r.EquipmentID = e.EquipmentID
                    WHERE 1=1 {statusFilter}
                    ORDER BY r.RequestDate DESC";

                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query, connection))
                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable dataTable = new DataTable();
                    adapter.Fill(dataTable);
                    DataGridRequests.ItemsSource = dataTable.DefaultView;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки данных: {ex.Message}", "Ошибка");
            }
        }

        private void BtnRefresh_Click(object sender, RoutedEventArgs e)
        {
            LoadData();
        }
    }
}