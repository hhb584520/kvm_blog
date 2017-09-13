#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <asm/uaccess.h>
#include <linux/rbtree.h>
#include <linux/slab.h>

struct vcpu_node {
  struct rb_node node;
  int vcpu_time;
};

struct rb_root root = RB_ROOT;

static void __add_node_to_tree(struct rb_root *tree, struct vcpu_node *node)
{
    struct rb_node **new = &tree->rb_node, *parent = NULL;
    struct vcpu_node *vnode;
    while (*new) {
        parent = *new;
        vnode = rb_entry(*new, struct vcpu_node, node);
        if (vnode->vcpu_time < node->vcpu_time)
            new = &((*new)->rb_left);
        else if (vnode->vcpu_time > node->vcpu_time)
            new = &((*new)->rb_right);
        else
            return;
    }
    rb_link_node(&node->node, parent, new);
    rb_insert_color(&node->node, tree);
}

static int __init hrb_tree_init(void)
{
    int i;
    struct rb_node *pnode;
    struct vcpu_node *pvcpu;

    for (i = 0; i < 3; ++i)
    {
	pvcpu = kmalloc(sizeof(struct vcpu_node), GFP_KERNEL);
        pvcpu->vcpu_time = i;
        __add_node_to_tree(&root, pvcpu);
    } 

    /* examples to iterator the tree */
    for (pnode = rb_first(&root); pnode; pnode = rb_next(pnode)) 
    {
        printk(KERN_INFO "vcpu_time = %d\n", rb_entry(pnode, struct vcpu_node, node)->vcpu_time);
    }

    return 0;
}

static void __exit hrb_tree_exit(void)
{
    struct rb_node *pnode;
    struct vcpu_node *pvcpu;

    for(pnode = rb_first(&root); pnode; pnode = rb_next(pnode))
    {
	pvcpu = rb_entry(pnode, struct vcpu_node, node);
        printk(KERN_INFO "delete vcpu_time = %d\n", rb_entry(pnode, struct vcpu_node, node)->vcpu_time);
        rb_erase(pnode, &root);	
        //kfree(pvcpu);
    }
}

module_init(hrb_tree_init);
module_exit(hrb_tree_exit);

MODULE_AUTHOR("Haibin Huang <hhb584520@163.com>");
MODULE_DESCRIPTION("An example of using the rbtree structure in the kernel");
MODULE_LICENSE("GPL");
