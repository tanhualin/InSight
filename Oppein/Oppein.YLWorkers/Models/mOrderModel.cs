using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Tech2020.InSight.Oppein.YLWorkers.Models
{
    public class mOrderModel
    {
        public int ordID { get; set; }
        public int ordOrderNo { get; set; }
        public string ordPONumber { get; set; }
        public string otpCode { get; set; }
        public string otpDescription { get; set; }
        public string ordSource { get; set; }
        public string ordOrderDate { get; set; }
        public string Factory { get; set; }
    }
}
