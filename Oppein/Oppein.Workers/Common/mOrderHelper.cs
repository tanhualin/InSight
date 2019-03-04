using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DevExpress.Data;

namespace Tech2020.InSight.Oppein.Workers.Common
{
    public class mOrderHelper
    {
        public static UnboundColumnType getGridColumnType(string DataType)
        {
            switch (DataType)
            {
                case "int":
                    return UnboundColumnType.Integer;
                case "boolean":
                    return UnboundColumnType.Boolean;
                case "decimal":
                    return UnboundColumnType.Decimal;
                case "datetime":
                    return UnboundColumnType.DateTime;
                case "string":
                    return UnboundColumnType.String;
                default:
                    return UnboundColumnType.Bound;
            }
        }
    }

    public enum ActionsType
    {
        sqlReplace=1,
        sqlAdd=2,
        sqlRemove=3,
        sqlUpdate=4,
        replace=5,
        add = 6,
        remove =7,
        update=8
    }
}
