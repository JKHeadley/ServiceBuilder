using %SERVICEBUILDER%.Model;
using %SERVICEBUILDER%.Repository;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace %SERVICEBUILDER%.Repository
{
    public partial class LoggingDecorator : I%SERVICEBUILDER%Repository
    {
        internal I%SERVICEBUILDER%Repository repo;
        private LoggingConfiguration_User loggingConfig_User = LoggingConfiguration_User.Instance;
        private LoggingConfiguration_PrimaryKeys loggingConfig_PrimaryKeys = LoggingConfiguration_PrimaryKeys.Instance;
        public LoggingDecorator(I%SERVICEBUILDER%Repository repo)
        {
            this.repo = repo;
        }

        public void LogError(Exception ex)
        {
            LogEvent log = new LogEvent();
            //log.LogEventType = LogEventType.Error;
            log.LogEventType = "Error";
            log.ChangedByUserId = this.GetCurrentUserId();
            log.ChangedByUserName = this.GetCurrentUserName();
            log.Date = DateTime.Now;

            Type entityType = ex.GetType();
            log.EntityType = entityType.Name;
            log.EntityId = "Error";

            var tempEx = ex;

            while (tempEx.StackTrace == null && ex.InnerException != null)
            {
                tempEx = tempEx.InnerException;
            }
            log.StackTrace = tempEx.StackTrace;

            while (tempEx.InnerException != null)
            {
                tempEx = tempEx.InnerException;
            }

            log.ErrorMessage = tempEx.Message;

            repo.UndoChanges();
            repo.Create<LogEvent>(log);
        }

        public T Create<T>(T t) where T : class
        {
            try
            {
                repo.Create<T>(t);

                // Log the Create event type
                LogEvent log = new LogEvent();
                //log.LogEventType = LogEventType.Create;
                log.LogEventType = "Create";

                // Log the user name, Id, and current date
                log.ChangedByUserId = this.GetCurrentUserId();
                log.ChangedByUserName = this.GetCurrentUserName();
                log.Date = DateTime.Now;

                // Log the newly created enitity type
                Type entityType = typeof(T);
                log.EntityType = entityType.Name;

                // Log the primary key/Id for the entity based on the config data
                // Note: This assumes the class names for the db model match the table names
                var configProp = loggingConfig_PrimaryKeys.GetType().GetProperty(entityType.Name);
                var primaryKeyName = configProp.GetValue(loggingConfig_PrimaryKeys, null).ToString();
                var entityProp = t.GetType().GetProperty(primaryKeyName);
                log.EntityId = entityProp.GetValue(t, null).ToString();

                // Save the log to the database
                repo.Create<LogEvent>(log);

                return t;
            }
            catch (Exception ex)
            {
                LogError(ex);
                throw ex;
            }
        }

        public T Update<T>(T t) where T : class
        {
            try
            {
                // Log the Create event type
                LogEvent log = new LogEvent();
                //log.LogEventType = LogEventType.Update;
                log.LogEventType = "Update";

                // Log the user name, Id, and current date
                log.ChangedByUserId = this.GetCurrentUserId();
                log.ChangedByUserName = this.GetCurrentUserName();
                log.Date = DateTime.Now;


                // Detach the etities so we can access both old and new values
                var entities = repo.All<T>().AsNoTracking();

                // Log the entity's type
                Type entityType = typeof(T);
                log.EntityType = entityType.Name;

                // Log the primary key/Id for the entity based on the config data
                // Note: This assumes the class names for the db model match the table names
                var configProp = loggingConfig_PrimaryKeys.GetType().GetProperty(entityType.Name);
                var primaryKeyName = configProp.GetValue(loggingConfig_PrimaryKeys, null).ToString();
                var entityProp = t.GetType().GetProperty(primaryKeyName);
                log.EntityId = entityProp.GetValue(t, null).ToString();

                // Get the current entity from the database with the "old" values
                var param = Expression.Parameter(typeof(T), "p");
                var exp = Expression.Lambda<Func<T, bool>>(
                    Expression.Equal(
                        Expression.Property(param, primaryKeyName),
                        Expression.Constant(entityProp.GetValue(t, null))
                    ),
                    param
                );
                var entity = (T)entities.Where(exp).ToList().ElementAt(0);

                // Compare old and new properties and log those that have changed
                foreach (var propInfo in t.GetType().GetProperties())
                {
                    var newValue = propInfo.GetValue(t, null);
                    var oldValue = propInfo.GetValue(entity, null);
                    var newValueString = "";
                    var oldValueString = "";
                    if (newValue != null)
                    {
                        newValueString = newValue.ToString();
                    }
                    if (oldValue != null)
                    {
                        oldValueString = oldValue.ToString();
                    }
                    if (newValue != null && oldValue != null && !newValueString.Equals(oldValueString) && !propInfo.PropertyType.Name.Contains("ICollection"))
                    {
                        log.PropertyName = propInfo.Name;
                        log.PropertyType = propInfo.PropertyType.Name;
                        log.OldValue = oldValueString;
                        log.NewValue = newValueString;
                        repo.Create<LogEvent>(log);
                    }
                }

                return repo.Update<T>(t);
            }
            catch (Exception ex)
            {
                LogError(ex);
                throw ex;
            }
        }

        public int Delete<T>(T t) where T : class
        {
            try
            {
                // Log the Create event type
                LogEvent log = new LogEvent();
                //log.LogEventType = LogEventType.Delete;
                log.LogEventType = "Delete";

                // Log the user name, Id, and current date
                log.ChangedByUserId = this.GetCurrentUserId();
                log.ChangedByUserName = this.GetCurrentUserName();
                log.Date = DateTime.Now;


                // Log the enitity type and primary key that will be deleted
                Type entityType = typeof(T);
                log.EntityType = entityType.Name;

                // Log the primary key/Id for the entity based on the config data
                // Note: This assumes the class names for the db model match the table names
                var configProp = loggingConfig_PrimaryKeys.GetType().GetProperty(entityType.Name);
                var primaryKeyName = configProp.GetValue(loggingConfig_PrimaryKeys, null).ToString();
                var entityProp = t.GetType().GetProperty(primaryKeyName);
                log.EntityId = entityProp.GetValue(t, null).ToString();

                // Save the log to the database
                repo.Create<LogEvent>(log);

                return repo.Delete<T>(t);
            }
            catch (Exception ex)
            {
                LogError(ex);
                throw ex;
            }
        }

        private string GetCurrentUserId()
        {
            // Grab the current user's username
            var changedByUserName = this.GetCurrentUserName();

            // Set the "Id" variable to the name of the primary key "Id" column as defined in the config
            var Id = loggingConfig_User.Id;

            // Get the user type defined in the config
            Type userType = Type.GetType(loggingConfig_User.UserTypeFullName + ", " + loggingConfig_User.UserTypeAssemblyName);

            // Create a generic expression in order to search for the user, matching the "UserName" column defined in the config
            const string methodSignature =
                "System.Linq.Expressions.Expression`1[TDelegate] Lambda[TDelegate]" +
                "(System.Linq.Expressions.Expression, System.Linq.Expressions.ParameterExpression[])";
            MethodInfo expression_method_Lambda = typeof(Expression).GetMethods().Single(m => m.ToString() == methodSignature);
            var func_type = typeof(Func<,>).MakeGenericType(userType, typeof(bool));
            MethodInfo expression_generic_Lambda = expression_method_Lambda.MakeGenericMethod(func_type);
            var param = Expression.Parameter(userType, "p");
            var exp = expression_generic_Lambda.Invoke(null, new object[] {
                    Expression.Equal(
                        Expression.Property(param, loggingConfig_User.UserName),
                        Expression.Constant(changedByUserName)
                    ),
                    new [] { param }
                });

            // Make a generic call to repo.Single using the recently acquired user type and expression
            MethodInfo repo_method_Single = repo.GetType().GetMethod("Single");
            MethodInfo repo_generic_Single = repo_method_Single.MakeGenericMethod(userType);
            var user = repo_generic_Single.Invoke(repo, new object[] { exp });

            if (user == null)
            {
                return "User: " + "\"" + changedByUserName + "\"" + " not found.";
            }

            // Get the primary key of the user return it
            var userIdProp = userType.GetProperty(Id);
            return(userIdProp.GetValue(user, null).ToString());
        }

        private string GetCurrentUserName()
        {
            // Grab the current user's username
            // TODO: set "changedByUserName" to the name of the current user
            var changedByUserName = "rootUser";
            return changedByUserName;
        }
    }


    public partial class LoggingDecorator : I%SERVICEBUILDER%Repository
    {
        public IQueryable<T> All<T>() where T : class
        {
            return repo.All<T>();
        }

        public IQueryable<T> Filter<T>(System.Linq.Expressions.Expression<Func<T, bool>> predicate) where T : class
        {
            return repo.Filter<T>(predicate);
        }

        public IQueryable<T> Filter<T>(System.Linq.Expressions.Expression<Func<T, bool>> filter, out int total, int index = 0, int size = 50) where T : class
        {
            return repo.Filter<T>(filter, out total, index, size);
        }

        public IQueryable<T> SelectByPartialText<T>(string text) where T : class
        {
            return repo.SelectByPartialText<T>(text);
        }

        public bool Contains<T>(System.Linq.Expressions.Expression<Func<T, bool>> predicate) where T : class
        {
            return repo.Contains<T>(predicate);
        }

        public T Find<T>(params object[] keys) where T : class
        {
            return repo.Find<T>(keys);
        }

        public T Find<T>(System.Linq.Expressions.Expression<Func<T, bool>> predicate) where T : class
        {
            return repo.Find<T>(predicate);
        }

        public int Delete<T>(System.Linq.Expressions.Expression<Func<T, bool>> predicate) where T : class
        {
            return repo.Delete<T>(predicate);
        }

        public T Single<T>(System.Linq.Expressions.Expression<Func<T, bool>> expression) where T : class
        {
            return repo.Single<T>(expression);
        }

        public void SaveChanges()
        {
            repo.SaveChanges();
        }

        public void ExecuteProcedure(string procedureCommand, params object[] sqlParams)
        {
            repo.ExecuteProcedure(procedureCommand, sqlParams);
        }

        public void Dispose()
        {
            repo.Dispose();
        }

        public void UndoChanges()
        {
            repo.UndoChanges();
        }
    }
}


