import sys
if sys.prefix == '/usr':
    sys.real_prefix = sys.prefix
    sys.prefix = sys.exec_prefix = '/rjd_projects/colcon_practice1/install/examples_rclpy_pointcloud_publisher'
