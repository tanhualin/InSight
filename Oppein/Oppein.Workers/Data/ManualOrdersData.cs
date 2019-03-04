using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Tech2020.InSight.Oppein.Workers.Data
{
    public class ManualOrdersData
    {
        public static Models.mOrderModel getManualOrderData(SqlConnection sqlConn, int algId)
        {
            var cmd = sqlConn.CreateCommand();
            cmd.CommandText = "dbo.spApp_GetManualOrdersHeader_OPP";
            cmd.CommandType = CommandType.StoredProcedure;

            var param = cmd.CreateParameter();
            param.ParameterName = "@algId";
            param.Direction = ParameterDirection.Input;
            param.DbType = DbType.Int32;
            param.Value = algId;
            cmd.Parameters.Add(param);

            SqlDataAdapter adp = new SqlDataAdapter();
            adp.SelectCommand = cmd;
            DataTable table = new DataTable();
            adp.Fill(table);
            return Common.CommonHelper.GetEntity<Models.mOrderModel>(table);
        }

        public static DataTable getTypeColumns(SqlConnection sqlconn)
        {
            var cmd = sqlconn.CreateCommand();
            cmd.CommandText = "dbo.spApp_GetManualOrdersTypeColumns_OPP";
            cmd.CommandType = CommandType.StoredProcedure;

            SqlDataAdapter adp = new SqlDataAdapter();
            adp.SelectCommand = cmd;
            DataTable table = new DataTable();
            adp.Fill(table);

            return table;
        }

        /// <summary>
        /// 根据订单号获取Grid信息
        /// </summary>
        /// <param name="sqlconn"></param>
        /// <param name="ordID"></param>
        /// <returns></returns>
        public static IList<Models.GridColumnModel> getGridColumnsData(SqlConnection sqlconn, int ordID,string otpCode,string ordSource)
        {
            var cmd = sqlconn.CreateCommand();
            cmd.CommandText = "dbo.spApp_GetManualOrdersGridColumns_OPP";
            cmd.CommandType = CommandType.StoredProcedure;

            var param = cmd.CreateParameter();
            param.ParameterName = "@ordID";
            param.Direction = ParameterDirection.Input;
            param.DbType = DbType.Int32;
            param.Value = ordID;
            cmd.Parameters.Add(param);

            var otpparam = cmd.CreateParameter();
            otpparam.ParameterName = "@otpCode";
            otpparam.Direction = ParameterDirection.Input;
            otpparam.DbType = DbType.String;
            otpparam.Value = otpCode;
            cmd.Parameters.Add(otpparam);

            var Ordparam = cmd.CreateParameter();
            Ordparam.ParameterName = "@ordSource";
            Ordparam.Direction = ParameterDirection.Input;
            Ordparam.DbType = DbType.String;
            Ordparam.Value = ordSource;
            cmd.Parameters.Add(Ordparam);

            SqlDataAdapter adp = new SqlDataAdapter();
            adp.SelectCommand = cmd;
            DataTable table = new DataTable();
            adp.Fill(table);
            return Common.CommonHelper.GetEntities<Models.GridColumnModel>(table);
        }

        /// <summary>
        /// 根据订单Id，获取普通订单柜身页签数据
        /// </summary>
        /// <param name="sqlconn"></param>
        /// <param name="ordID"></param>
        /// <returns></returns>
        public static DataTable getManualOrdersNormal_GS(SqlConnection sqlconn, int ordID)
        {
            var cmd = sqlconn.CreateCommand();
            cmd.CommandText = "dbo.spApp_GetManualOrdersNormal_GS_OPP";
            cmd.CommandType = CommandType.StoredProcedure;

            var param = cmd.CreateParameter();
            param.ParameterName = "@ordID";
            param.Direction = ParameterDirection.Input;
            param.DbType = DbType.Int32;
            param.Value = ordID;
            cmd.Parameters.Add(param);

            SqlDataAdapter adp = new SqlDataAdapter();
            adp.SelectCommand = cmd;
            DataTable table = new DataTable();
            adp.Fill(table);
            return table;
        }

        public static DataTable getStoredProcedureData(SqlConnection sqlCon, string storedProcedure)
        {
            var cmd = sqlCon.CreateCommand();
            cmd.CommandText = storedProcedure;
            cmd.CommandType = CommandType.StoredProcedure;

            SqlDataAdapter adp = new SqlDataAdapter();
            adp.SelectCommand = cmd;
            DataTable table = new DataTable();
            adp.Fill(table);

            return table;
        }

        public static DataTable getStoredProcedureData(SqlConnection sqlCon, string storedProcedure,int ordId)
        {
            var cmd = sqlCon.CreateCommand();
            cmd.CommandText = storedProcedure;
            cmd.CommandType = CommandType.StoredProcedure;

            var param = cmd.CreateParameter();
            param.ParameterName = "@ordID";
            param.Direction = ParameterDirection.Input;
            param.DbType = DbType.Int32;
            param.Value = ordId;
            cmd.Parameters.Add(param);

            SqlDataAdapter adp = new SqlDataAdapter();
            adp.SelectCommand = cmd;
            DataTable table = new DataTable();
            adp.Fill(table);

            return table;
        }

        public static DataTable getComboBoxData(SqlConnection sqlCon, string storedProcedure,string bindValue, string keyValueEx)
        {
            var cmd = sqlCon.CreateCommand();
            cmd.CommandText = storedProcedure;
            cmd.CommandType = CommandType.StoredProcedure;

            var param = cmd.CreateParameter();
            param.ParameterName = "@keyWordEx";
            param.Direction = ParameterDirection.Input;
            param.DbType = DbType.String;
            param.Value = keyValueEx;
            cmd.Parameters.Add(param);

            var bindParam = cmd.CreateParameter();
            bindParam.ParameterName = "@bindValue";
            bindParam.Direction = ParameterDirection.Input;
            bindParam.DbType = DbType.String;
            bindParam.Value = bindValue;
            cmd.Parameters.Add(bindParam);

            SqlDataAdapter adp = new SqlDataAdapter();
            adp.SelectCommand = cmd;
            DataTable table = new DataTable();
            adp.Fill(table);

            return table;
        }
        public static DataTable getComboBoxData(SqlConnection sqlCon, string storedProcedure, string keyValueEx)
        {
            var cmd = sqlCon.CreateCommand();
            cmd.CommandText = storedProcedure;
            cmd.CommandType = CommandType.StoredProcedure;

            var param = cmd.CreateParameter();
            param.ParameterName = "@keyWordEx";
            param.Direction = ParameterDirection.Input;
            param.DbType = DbType.String;
            param.Value = keyValueEx;
            cmd.Parameters.Add(param);

            SqlDataAdapter adp = new SqlDataAdapter();
            adp.SelectCommand = cmd;
            DataTable table = new DataTable();
            adp.Fill(table);

            return table;
        }
        public static DataTable getComboBoxData(SqlConnection sqlCon, string storedProcedure)
        {
            var cmd = sqlCon.CreateCommand();
            cmd.CommandText = storedProcedure;
            cmd.CommandType = CommandType.StoredProcedure;
            SqlDataAdapter adp = new SqlDataAdapter();
            adp.SelectCommand = cmd;
            DataTable table = new DataTable();
            adp.Fill(table);

            return table;
        }
        public static void getMOrdItemDimensions(SqlConnection sqlCon, decimal dimFX, decimal dimFY, decimal dimFZ,
            string edgeCode, string topSurCode, int WenLi, ref double dimCX, ref double dimCY)
        {
            var cmd = sqlCon.CreateCommand();
            cmd.CommandTimeout = 60;
            cmd.CommandText = "[dbo].[spAPP_getMOrdItemDimensions_OPP]";
            cmd.CommandType = CommandType.StoredProcedure;

            var dimFxParam = cmd.CreateParameter();
            dimFxParam.ParameterName = "@dimFX";
            dimFxParam.DbType = DbType.Decimal;
            dimFxParam.Direction = ParameterDirection.Input;
            dimFxParam.Value = dimFX;
            cmd.Parameters.Add(dimFxParam);

            var dimFYParam = cmd.CreateParameter();
            dimFYParam.ParameterName = "@dimFY";
            dimFYParam.DbType = DbType.Decimal;
            dimFYParam.Direction = ParameterDirection.Input;
            dimFYParam.Value = dimFY;
            cmd.Parameters.Add(dimFYParam);

            var dimFZParam = cmd.CreateParameter();
            dimFZParam.ParameterName = "@dimFZ";
            dimFZParam.DbType = DbType.Decimal;
            dimFZParam.Direction = ParameterDirection.Input;
            dimFZParam.Value = dimFZ;
            cmd.Parameters.Add(dimFZParam);

            var edgeParam = cmd.CreateParameter();
            edgeParam.ParameterName = "@edgeCode";
            edgeParam.DbType = DbType.String;
            edgeParam.Direction = ParameterDirection.Input;
            edgeParam.Value = edgeCode;
            cmd.Parameters.Add(edgeParam);

            var topSurParam = cmd.CreateParameter();
            topSurParam.ParameterName = "@topSurCode";
            topSurParam.DbType = DbType.String;
            topSurParam.Direction = ParameterDirection.Input;
            topSurParam.Value = topSurCode;
            cmd.Parameters.Add(topSurParam);

            var wParam = cmd.CreateParameter();
            wParam.ParameterName = "@WenLi";
            wParam.DbType = DbType.Int16;
            wParam.Direction = ParameterDirection.Input;
            wParam.Value = WenLi;
            cmd.Parameters.Add(wParam);

            var dimCXParam = cmd.CreateParameter();
            dimCXParam.ParameterName = "@dimCX";
            dimCXParam.DbType = DbType.Double;
            dimCXParam.Direction = ParameterDirection.Output;
            //dimCXParam.Value = dimCX;
            cmd.Parameters.Add(dimCXParam);

            var dimCYParam = cmd.CreateParameter();
            dimCYParam.ParameterName = "@dimCY";
            dimCYParam.DbType = DbType.Double;
            dimCYParam.Direction = ParameterDirection.Output;
            //dimCYParam.Value = dimCY;
            cmd.Parameters.Add(dimCYParam);

            cmd.ExecuteNonQuery();

            if (dimCXParam.Value != null && dimCXParam.Value!=DBNull.Value)
            {
                dimCX = Convert.ToDouble(dimCXParam.Value);
            }
            if (dimCYParam.Value != null && dimCYParam.Value!=DBNull.Value)
            {
                dimCY = Convert.ToDouble(dimCYParam.Value);
            }
        }

        /// <summary>
        /// 批量保存操作数据
        /// </summary>
        /// <param name="conn"></param>
        /// <param name="table"></param>
        public static void utlMOrdEditingBatch(SqlConnection conn, int ordID,string pageName,string ordSource, DataTable table)
        {
            var cmd = conn.CreateCommand();
            cmd.CommandTimeout = 60;
            cmd.CommandText = "dbo.spAPP_utlMOrdEditingBatch_OPP";
            cmd.CommandType = CommandType.StoredProcedure;
            //存储过程参数及值
            cmd.Parameters.Add("@mOrdItmTable", SqlDbType.Structured);
            cmd.Parameters[0].Value = table;

            var ordIDParam = cmd.CreateParameter();
            ordIDParam.ParameterName = "@ordID";
            ordIDParam.DbType = DbType.Int32;
            ordIDParam.Direction = ParameterDirection.Input;
            ordIDParam.Value = ordID;
            cmd.Parameters.Add(ordIDParam);

            var pageParam = cmd.CreateParameter();
            pageParam.ParameterName = "@pageName";
            pageParam.DbType = DbType.String;
            pageParam.Direction = ParameterDirection.Input;
            pageParam.Value = pageName;
            cmd.Parameters.Add(pageParam);

            var sParam = cmd.CreateParameter();
            sParam.ParameterName = "@ordSource";
            sParam.DbType = DbType.String;
            sParam.Direction = ParameterDirection.Input;
            sParam.Value = ordSource;
            cmd.Parameters.Add(sParam);

            cmd.ExecuteNonQuery();
        }
    }
}
