#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/list.h>
#include <linux/slab.h>

struct Person {
    char name[30];
    unsigned char gender;
    struct list_head list; /* kernel's list structure */
};
 
struct Person personList;
 
static int hlist_init(void)
{
    struct Person *aNewPerson, *aPerson;
    unsigned int i;
 
    printk(KERN_INFO "initialize hlist module\n");
    INIT_LIST_HEAD(&personList.list);    //or LIST_HEAD(mylist); 
 
    /* adding elements to mylist */
    for(i=0; i<3; ++i){
        aNewPerson = kmalloc(sizeof(*aNewPerson), GFP_KERNEL);
        strcpy(aNewPerson->name, "haibin");
        aNewPerson->gender = 1 & i;
        INIT_LIST_HEAD(&aNewPerson->list);
        /* add the new node to mylist */
        list_add_tail(&(aNewPerson->list), &(personList.list));
    }
    printk(KERN_INFO "traversing the list using list_for_each_entry()\n");
    list_for_each_entry(aPerson, &personList.list, list) {
        //access the member from aPerson
        printk(KERN_INFO "Person: %s; gender: %s\n", aPerson->name, aPerson->gender==0?"Female":"Male");
    }
    printk(KERN_INFO "n");
 
    return 0;
}
 
static void hlist_exit(void)
{
    struct Person *aPerson, *tmp;
    printk(KERN_INFO "unloaded hlist module.\n");
    printk(KERN_INFO "deleting the list using list_for_each_entry_safe()\n");
    list_for_each_entry_safe(aPerson, tmp, &personList.list, list){
         printk(KERN_INFO "freeing node %s\n", aPerson->name);
         list_del(&aPerson->list);
         kfree(aPerson);
    }
}

module_init(hlist_init);
module_exit(hlist_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Haibin Huang");
MODULE_DESCRIPTION("kernel list examples.");
