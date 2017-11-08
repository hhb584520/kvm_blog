# 1. Mysql
## 1.1 install mysql

    $ yum install mysql -y

## 1.2 use mysql

To connect to MySQL from the command line, follow these steps:
	
- Log in to your A2 Hosting account using SSH.
- At the command line, type the following command, replacing USERNAME with your username
  
    ***mysql -u USERNAME -p***

- At the Enter Password prompt, type your password. When you type the correct password
    
	***mysql> prompt appears.***

- To display a list of databases, type the following command at the mysql> prompt:
	
	***show databases;***
	
- To access a specific database, type the following command at the mysql> prompt, replacing DBNAME with the database that you want to access:
	
	***use DBNAME;***


# 2. Python 
## 2.1 install conector for python

	$ yum install mysql-connector-python.x86_64

## 2.2 install orm(sqlalchemy)

    $ yum install python-sqlalchemy.x86_64

# 3. orm(sqlalchemy)
## 3.1 介绍


orm英文全称object relational mapping,就是对象映射关系程序，简单来说我们类似python这种面向对象的程序来说一切皆对象，但是我们使用的数据库却都是关系型的，为了保证一致的使用习惯，通过orm将编程语言的对象模型和数据库的关系模型建立映射关系，这样我们在使用编程语言对数据库进行操作的时候可以直接使用编程语言的对象模型进行操作就可以了，而不用直接使用sql语言。


sqlalchemy 是 Python 的 orm 程序，在整个 Python 界当中相当出名。

## 3.2 full code examples
	[root@hhb-kvm others]# cat orm.py
	from sqlalchemy.orm import mapper, sessionmaker
	from sqlalchemy import create_engine,Table,Column,Integer,String,MetaData,ForeignKey
	from sqlalchemy.sql.expression import Cast
	from sqlalchemy.ext.compiler import compiles
	
	
	engine=create_engine("mysql://root:123456@localhost:3306/TESTDB",echo=True)
	metadata=MetaData(engine)
	
	user_table=Table('user',metadata,
	     Column('id',Integer,primary_key=True),
	         Column('name',String(20)),
	         Column('fullname',String(40)),
	         )
	
	address_table = Table('address', metadata,
	     Column('id', Integer, primary_key=True),
	         Column('user_id', None, ForeignKey('user.id')),
	         Column('email', String(128), nullable=False)
	         )
	
	metadata.create_all()
	
	class User(object):
	    pass
	
	mapper(User, user_table)
	Session=sessionmaker()
	
	Session.configure(bind=engine)
	session = Session()
	
	def main():
	        # insert table
	        u = User()
	        u.name='ywh'
	        u.fullname='weihong'
	        session.add(u)
	        session.flush()
	        session.commit()
	
	        # query table
	        query = session.query(User)
	        print list(query)
	        print query.get(2)
	        print query.filter_by(name='ywh').first()
	        u = query.filter_by(name='ywh').first()
	        u.fullname='yingweihong'
	        session.commit()
	
	        print query.get(2).fullname
	
	        session.close()
	
	
	if __name__ == '__main__':
	        main()



