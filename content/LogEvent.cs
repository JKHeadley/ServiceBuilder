using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace %SERVICEBUILDER%.Model
{
    public enum LogEventType
    {
        Create,
        Update,
        Delete,
        Error
    }
    public partial class LogEvent
    {
        public int Id { get; set; }
        public string LogEventType { get; set; }//would like to use an enum here, but also want the db entry to be readable
        public string EntityType { get; set; }
        public string EntityId { get; set; }
        public string ChangedByUserId { get; set; }
        public string ChangedByUserName { get; set; }
        public DateTime Date { get; set; }
        public string PropertyName { get; set; }
        public string PropertyType { get; set; }
        public string OldValue { get; set; }
        public string NewValue { get; set; }
        public string ErrorMessage { get; set; }
        public string StackTrace { get; set; }
    }
}
