using %SERVICEBUILDER%.Model;
using %SERVICEBUILDER%.Repository;
using Castle.MicroKernel.Registration;
using Castle.MicroKernel.SubSystems.Configuration;
using Castle.Windsor;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;

namespace %SERVICEBUILDER%.Service.Installers
{
    public class RepositoryInstaller : IWindsorInstaller
    {
        public void Install(IWindsorContainer container, IConfigurationStore store)
        {
            container.Register(Component.For<DbContext>()
                .ImplementedBy<%SERVICEBUILDER%Context>()
                .LifestyleSingleton());

            container.Register(Component.For<I%SERVICEBUILDER%Repository>()
                .ImplementedBy<%SERVICEBUILDER%Repository>()
                .LifestyleSingleton());
        }
    }
}