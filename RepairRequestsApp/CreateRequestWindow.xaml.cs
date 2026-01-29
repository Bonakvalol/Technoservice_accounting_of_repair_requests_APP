using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows;
using System.Windows.Controls;
using QRCoder;
using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Color = System.Drawing.Color;
using Bitmap = System.Drawing.Bitmap;
using System.Drawing.Imaging;

namespace RepairRequestsApp
{
    public partial class CreateRequestWindow : Window
    {
        private string connectionString;

        public CreateRequestWindow(string connectionString)
        {
            InitializeComponent();
            this.connectionString = connectionString;
            LoadData();
        }

        private void LoadData()
        {
            try
            {
                LoadComboBoxData();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки данных: {ex.Message}", "Ошибка");
            }
        }

        private void LoadComboBoxData()
        {
            string clientsQuery = "SELECT ClientID, LastName + ' ' + FirstName AS FullName FROM Clients";
            FillComboBox(CbClients, clientsQuery, "FullName", "ClientID");

            string equipmentQuery = @"
                SELECT e.EquipmentID, 
                       e.Model + ' (' + e.SerialNumber + ')' AS EquipmentInfo
                FROM Equipment e
                WHERE e.Status IN ('Исправен', 'Резерв')";
            FillComboBox(CbEquipment, equipmentQuery, "EquipmentInfo", "EquipmentID");

            string faultTypesQuery = "SELECT FaultTypeID, TypeName FROM FaultTypes";
            FillComboBox(CbFaultTypes, faultTypesQuery, "TypeName", "FaultTypeID");
        }

        private void FillComboBox(ComboBox comboBox, string query, string displayMember, string valueMember)
        {
            try
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query, connection))
                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable dataTable = new DataTable();
                    adapter.Fill(dataTable);

                    comboBox.DisplayMemberPath = displayMember;
                    comboBox.SelectedValuePath = valueMember;
                    comboBox.ItemsSource = dataTable.DefaultView;

                    if (dataTable.Rows.Count > 0)
                        comboBox.SelectedIndex = 0;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки {comboBox.Name}: {ex.Message}", "Ошибка");
            }
        }

        private string GetClientName(int clientId)
        {
            try
            {
                string query = "SELECT LastName + ' ' + FirstName AS ClientName FROM Clients WHERE ClientID = @ClientID";
                
                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@ClientID", clientId);
                    connection.Open();
                    return command.ExecuteScalar()?.ToString() ?? "Неизвестный клиент";
                }
            }
            catch (Exception)
            {
                return "Неизвестный клиент";
            }
        }

        private string GetEquipmentInfo(int equipmentId)
        {
            try
            {
                string query = "SELECT Model + ' (' + SerialNumber + ')' AS EquipmentInfo FROM Equipment WHERE EquipmentID = @EquipmentID";
                
                using (SqlConnection connection = new SqlConnection(connectionString))
                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@EquipmentID", equipmentId);
                    connection.Open();
                    return command.ExecuteScalar()?.ToString() ?? "Неизвестное оборудование";
                }
            }
            catch (Exception)
            {
                return "Неизвестное оборудование";
            }
        }

        private void GenerateQRCode(int requestId, string requestNumber, string clientName, string equipmentInfo, string problemDescription)
        {
            try
            {
                string qrContent = $"ЗАЯВКА НА РЕМОНТ №{requestNumber}\n\n" +
                                  $"Дата создания: {DateTime.Now:dd.MM.yyyy HH:mm}\n" +
                                  $"Клиент: {clientName}\n" +
                                  $"Оборудование: {equipmentInfo}\n" +
                                  $"Описание проблемы:\n{problemDescription}\n\n" +
                                  $"ID заявки: {requestId}\n" +
                                  $"Для связи: техподдержка@сервис.рф\n" +
                                  $"Тел.: +7 (999) 123-45-67";

                QRCodeGenerator qrGenerator = new QRCodeGenerator();
                QRCodeData qrCodeData = qrGenerator.CreateQrCode(qrContent, QRCodeGenerator.ECCLevel.Q);
                QRCode qrCode = new QRCode(qrCodeData);
                
                Bitmap qrCodeBitmap = qrCode.GetGraphic(20, Color.Black, Color.White, true);
                
                string qrCodesFolder = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "QR_Codes");
                
                if (!Directory.Exists(qrCodesFolder))
                {
                    Directory.CreateDirectory(qrCodesFolder);
                }
                
                string cleanRequestNumber = requestNumber.Replace(":", "_").Replace("/", "_").Replace("\\", "_");
                string fileName = $"QR_{cleanRequestNumber}.png";
                string filePath = Path.Combine(qrCodesFolder, fileName);
                
                qrCodeBitmap.Save(filePath, ImageFormat.Png);

                UpdateQRCodeInDatabase(requestId, filePath);
                
             
                ShowQRCodeWindow(qrCodeBitmap, requestNumber, filePath);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка при генерации QR-кода: {ex.Message}\nЗаявка создана, но QR-код не сгенерирован.", "Предупреждение");
            }
        }

        private void UpdateQRCodeInDatabase(int requestId, string filePath)
        {
            try
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    string query = @"
                        UPDATE RepairRequests 
                        SET QRCodePath = @QRCodePath
                        WHERE RequestID = @RequestID";
                    
                    using (SqlCommand command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@RequestID", requestId);
                        command.Parameters.AddWithValue("@QRCodePath", filePath);
                        
                        command.ExecuteNonQuery();
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка сохранения QR-кода в БД: {ex.Message}");
            }
        }

        private void ShowQRCodeWindow(Bitmap qrCodeBitmap, string requestNumber, string filePath)
        {
            try
            {
               
                BitmapImage bitmapImage = new BitmapImage();
                using (MemoryStream memory = new MemoryStream())
                {
                    qrCodeBitmap.Save(memory, ImageFormat.Png);
                    memory.Position = 0;
                    bitmapImage.BeginInit();
                    bitmapImage.StreamSource = memory;
                    bitmapImage.CacheOption = BitmapCacheOption.OnLoad;
                    bitmapImage.EndInit();
                }

              
                Window qrWindow = new Window
                {
                    Title = $"QR-код заявки {requestNumber}",
                    Width = 400,
                    Height = 500,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner,
                    Owner = this,
                    ResizeMode = ResizeMode.NoResize
                };

                StackPanel stackPanel = new StackPanel
                {
                    Margin = new Thickness(20),
                    Background = Brushes.White
                };

                TextBlock titleText = new TextBlock
                {
                    Text = $"QR-код заявки {requestNumber}",
                    FontSize = 18,
                    FontWeight = FontWeights.Bold,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    Margin = new Thickness(0, 0, 0, 20)
                };

                Border imageBorder = new Border
                {
                    BorderBrush = Brushes.LightGray,
                    BorderThickness = new Thickness(2),
                    Padding = new Thickness(10),
                    HorizontalAlignment = HorizontalAlignment.Center,
                    Margin = new Thickness(0, 0, 0, 20)
                };

                Image qrImage = new Image
                {
                    Source = bitmapImage,
                    Width = 250,
                    Height = 250,
                    Stretch = Stretch.Uniform
                };

                imageBorder.Child = qrImage;

                TextBlock infoText = new TextBlock
                {
                    Text = $"QR-код сохранен в файл:\n{filePath}\n\nОтсканируйте код для быстрого доступа к информации о заявке.",
                    TextWrapping = TextWrapping.Wrap,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    TextAlignment = TextAlignment.Center,
                    Margin = new Thickness(0, 0, 0, 20)
                };

                Button closeButton = new Button
                {
                    Content = "Закрыть",
                    Width = 100,
                    Height = 30,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    Background = Brushes.LightBlue,
                    Margin = new Thickness(0, 10, 0, 0)
                };

                closeButton.Click += (s, e) => qrWindow.Close();

                stackPanel.Children.Add(titleText);
                stackPanel.Children.Add(imageBorder);
                stackPanel.Children.Add(infoText);
                stackPanel.Children.Add(closeButton);

                qrWindow.Content = stackPanel;
                qrWindow.ShowDialog();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка отображения QR-кода: {ex.Message}", "Ошибка");
            }
        }

        private void BtnCreate_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                if (CbClients.SelectedValue == null)
                {
                    MessageBox.Show("Выберите клиента", "Ошибка");
                    return;
                }

                if (CbEquipment.SelectedValue == null)
                {
                    MessageBox.Show("Выберите оборудование", "Ошибка");
                    return;
                }

                if (CbFaultTypes.SelectedValue == null)
                {
                    MessageBox.Show("Выберите тип неисправности", "Ошибка");
                    return;
                }

                if (string.IsNullOrWhiteSpace(TxtProblem.Text))
                {
                    MessageBox.Show("Введите описание проблемы", "Ошибка");
                    return;
                }

                int clientId = Convert.ToInt32(CbClients.SelectedValue);
                int equipmentId = Convert.ToInt32(CbEquipment.SelectedValue);
                int faultTypeId = Convert.ToInt32(CbFaultTypes.SelectedValue);
                string problemDescription = TxtProblem.Text;

                int priority = 3; 
                if (CbPriority.SelectedItem is ComboBoxItem item)
                {
                    string content = item.Content.ToString();
                    if (content.StartsWith("1")) priority = 1;
                    else if (content.StartsWith("2")) priority = 2;
                    else if (content.StartsWith("3")) priority = 3;
                    else if (content.StartsWith("4")) priority = 4;
                    else if (content.StartsWith("5")) priority = 5;
                }

                string requestNumber = GenerateRequestNumber();

                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    string insertQuery = @"
                        INSERT INTO RepairRequests 
                        (RequestNumber, ClientID, EquipmentID, FaultTypeID, 
                         ProblemDescription, Priority, RequestDate, Status)
                        VALUES 
                        (@RequestNumber, @ClientID, @EquipmentID, @FaultTypeID, 
                         @ProblemDescription, @Priority, GETDATE(), 'В ожидании');
                        
                        SELECT SCOPE_IDENTITY();";

                    int newRequestId = 0;
                    
                    using (SqlCommand command = new SqlCommand(insertQuery, connection))
                    {
                        command.Parameters.AddWithValue("@RequestNumber", requestNumber);
                        command.Parameters.AddWithValue("@ClientID", clientId);
                        command.Parameters.AddWithValue("@EquipmentID", equipmentId);
                        command.Parameters.AddWithValue("@FaultTypeID", faultTypeId);
                        command.Parameters.AddWithValue("@ProblemDescription", problemDescription);
                        command.Parameters.AddWithValue("@Priority", priority);

                        newRequestId = Convert.ToInt32(command.ExecuteScalar());
                    }

                    if (newRequestId > 0)
                    {
                    
                        if (CbGenerateQR.IsChecked == true)
                        {
                            string clientName = GetClientName(clientId);
                            string equipmentInfo = GetEquipmentInfo(equipmentId);
                            
                           
                            GenerateQRCode(newRequestId, requestNumber, clientName, equipmentInfo, problemDescription);
                        }

                        MessageBox.Show($"Заявка успешно создана!\nНомер: {requestNumber}", "Успех");
                        this.DialogResult = true;
                        this.Close();
                    }
                    else
                    {
                        MessageBox.Show("Не удалось создать заявку", "Ошибка");
                    }
                }
            }
            catch (SqlException sqlEx)
            {
                string errorMessage = GetUserFriendlyErrorMessage(sqlEx);
                MessageBox.Show(errorMessage, "Ошибка базы данных");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка: {ex.Message}", "Ошибка");
            }
        }

        private string GenerateRequestNumber()
        {
            return $"RR-{DateTime.Now:yyyyMMdd}-{DateTime.Now:HHmmss}";
        }

        private string GetUserFriendlyErrorMessage(SqlException sqlEx)
        {
            switch (sqlEx.Number)
            {
                case 547: 
                    return "Выбранные данные не существуют. Возможно, были удалены из базы.";
                case 2627: 
                    return "Заявка с таким номером уже существует.";
                case 515: 
                    return "Не все обязательные поля заполнены.";
                default:
                    return $"Ошибка базы данных: {sqlEx.Message}";
            }
        }

        private void BtnCancel_Click(object sender, RoutedEventArgs e)
        {
            this.DialogResult = false;
            this.Close();
        }
    }
}