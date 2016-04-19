using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.Entity.ModelConfiguration.Conventions;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace %SERVICEBUILDER%.Model
{
    public partial class %SERVICEBUILDER%Context : DbContext
    {
        public DbSet<LogEvent> LogEvents { get; set; }
    }
}
