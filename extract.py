import pandas as pd

# 定义输入文件和输出文件
input_file = r'C:\毕业设计-源汇匹配数据\2051-2060源汇距离.txt'
output_file = r'C:\毕业设计-源汇匹配数据\源汇距离2051_2060.csv'

# 使用chunksize参数逐块读取大文件
chunk_size = 10000  # 每次读取的行数
columns_to_extract = [1, 2, 3]  # 需要提取的列索引（0基索引）

# 逐块读取文件
for chunk in pd.read_csv(input_file, header=None, chunksize=chunk_size):
    # 提取所需的列
    extracted_columns = chunk.iloc[:, columns_to_extract]
    # 追加到CSV文件中
    extracted_columns.to_csv(output_file, mode='a', index=False, header=False)

# 如果你希望在第一次写入时创建文件并写入表头，可以单独处理
if not pd.io.common.file_exists(output_file):
    # 如果文件不存在，写入表头
    extracted_columns.to_csv(output_file, mode='w', index=False, header=False)
