using System.Data.SqlClient;
using System.Threading;
using System.Windows.Forms;
using NUnit.Framework;

namespace Tech2020.InSight.Oppein.Workers
{
    [TestFixture]
    public class ManualOrdersWorker
    {
        /// <summary>
        /// 测试
        /// </summary>
        [Test]
        public void CanTest()
        {
            Thread InvokeThread = new Thread(new ThreadStart(InvokeCanTestXtralTab));
            InvokeThread.SetApartmentState(ApartmentState.STA);
            InvokeThread.Start();
            InvokeThread.Join();
        }
        public void InvokeCanTestXtralTab()
        {
           
            var form = new ManualOrdersForm(123);
            form.WindowState = FormWindowState.Maximized;
            // 设置全屏
            form.ShowDialog();
        }


        /// <summary>
        /// 测试
        /// </summary>
        [Test]
        public void CanMOrdFormTest()
        {
            //int s = 1;
            //bool b = Convert.ToBoolean(s);
            //int rgb = Color.Yellow.ToArgb() & 0xFFFFFF;
            //var s = "#" + rgb.ToString("X6");
            Thread InvokeThread = new Thread(new ThreadStart(InvokeCanTestMOrdForm));
            InvokeThread.SetApartmentState(ApartmentState.STA);
            InvokeThread.Start();
            InvokeThread.Join();
        }
        public void InvokeCanTestMOrdForm()
        {
            //SqlConnection sqlConn = new SqlConnection("Data Source=10.10.200.4;Initial Catalog=inSight;User ID=Leo;Password=2020;Connect Timeout=15;");
            SqlConnection sqlConn = new SqlConnection("Data Source=10.10.200.36;Initial Catalog=inSight_B;User ID=Leo;Password=Leo;Connect Timeout=15;");
            sqlConn.Open();
            var form = new Forms.mOrdersForm(sqlConn, 1923491);//4619068 //40270745//2032//1923491 //CAD实木2154267 5493258
            form.WindowState = FormWindowState.Maximized;
            // 设置全屏
            form.ShowDialog();
        }
    }
}
