using %SERVICEBUILDER%.Service.Helpers;
using %SERVICEBUILDER%.Model;
using %SERVICEBUILDER%.Repository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;
using System.Transactions;
using Castle.Windsor;
using Castle.Windsor.Installer;

namespace %SERVICEBUILDER%.Service
{
    public class Service : IService
    {
        public Service()
        {
        }
    }
}
